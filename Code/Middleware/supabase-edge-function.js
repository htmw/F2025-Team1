// deno-lint-ignore-file no-explicit-any
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-admin-secret, user_id'
};
const DEBUG = (Deno.env.get('DEBUG_LOGS') ?? '').toLowerCase() === 'true';
function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...corsHeaders
    }
  });
}
const badRequest = (msg) => json({
  error: msg
}, 400);
const forbidden = () => json({
  error: 'Forbidden'
}, 403);
const unauthorized = () => json({
  error: 'Unauthorized'
}, 401);
const notFound = (msg = 'Not found') => json({
  error: msg
}, 404);
async function readJson(req) {
  try {
    const body = await req.text();
    if (!body) return null;
    return JSON.parse(body);
  } catch  {
    return null;
  }
}
serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', {
    headers: corsHeaders
  });
  const url = new URL(req.url);
  // ---- Path normalization: works for legacy/local and new functions domain ----
  let path = url.pathname;
  path = path.replace(/^\/functions\/v\d+\/app-middleware/i, '').replace(/^\/app-middleware/i, '');
  if (path === '') path = '/';
  const method = req.method.toUpperCase();
  // Request diagnostics (safe)
  if (DEBUG) {
    const origin = req.headers.get('origin') ?? '∅';
    const authHdr = req.headers.get('authorization') ?? '∅';
    const adminHdr = req.headers.get('x-admin-secret') ? 'present' : 'absent';
    console.log('[req]', {
      method,
      rawPath: url.pathname,
      normPath: path,
      origin,
      hasAuth: authHdr !== '∅',
      adminHdr
    });
  }
  // ---- Admin guard ----
  const providedSecret = req.headers.get('x-admin-secret');
  const expectedSecret = Deno.env.get('EDGE_ADMIN_SECRET') ?? '';
  if (!expectedSecret || providedSecret !== expectedSecret) {
    if (DEBUG) console.log('[guard] forbidden: missing/incorrect x-admin-secret');
    return forbidden();
  }
  // ---- Env & client init ----
  const supabaseUrl = (Deno.env.get('SUPABASE_URL') ?? '').trim();
  const serviceKey = (Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '').trim();
  if (DEBUG) console.log('[env]', {
    hasUrl: !!supabaseUrl,
    hasServiceKey: !!serviceKey
  });
  if (!supabaseUrl || !serviceKey) {
    return json({
      error: 'Server misconfig: missing URL or SERVICE_ROLE key'
    }, 500);
  }
  // ensure no trailing slash when building admin URL
  const supabaseUrlNoSlash = supabaseUrl.endsWith('/') ? supabaseUrl.slice(0, -1) : supabaseUrl;

  const db = createClient(supabaseUrl, serviceKey, {
    auth: {
      persistSession: false
    }
  });
  try {
    // -------------------------------
    // POST /signup
    // Body: { email, password, name? }
    // Uses admin API via SERVICE_ROLE key to create auth user
    // -------------------------------
    if (path === '/signup' && method === 'POST') {
      const body = await readJson(req);
      if (!body) return badRequest('Invalid or empty JSON');
      const { email, password, name } = body;
      if (!email || !password) return badRequest('Missing email or password');
      if (name != null && (typeof name !== 'string' || name.trim() === '')) return badRequest('If provided, name must be a non-empty string');

      // Build payload for admin API
      const payload = {
        email,
        password,
        email_confirm: true
      };
      if (name != null) {
        payload.user_metadata = { name: name.trim() };
      }

      // Call Supabase Admin API directly using service role
      const adminResp = await fetch(`${supabaseUrlNoSlash}/auth/v1/admin/users`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'apikey': serviceKey,
          'Authorization': `Bearer ${serviceKey}`
        },
        body: JSON.stringify(payload)
      });

      // Try parse JSON; if parsing fails, fallback to text
      let adminData = null;
      try {
        adminData = await adminResp.clone().json();
      } catch {
        try {
          adminData = await adminResp.clone().text();
        } catch {
          adminData = null;
        }
      }

      if (!adminResp.ok) {
        if (DEBUG) console.log('[signup][admin-error]', adminResp.status, adminData);
        return json({
          error: adminData ?? { status: adminResp.status }
        }, adminResp.status === 200 ? 400 : adminResp.status);
      }

      return json({
        user: adminData
      }, 201);
    }

    // -------------------------------
    // GET /login?email=<email>&password=<password>
    // Logs a user in by calling Supabase Auth REST API directly (password grant)
    // Similar to /signup which calls the Auth REST Admin API directly.
    // -------------------------------
    if (path === '/login' && method === 'GET') {
      const email = url.searchParams.get('email');
      const password = url.searchParams.get('password');
      if (!email || !password) return badRequest('Missing email or password');

      // Supabase Auth REST endpoint for email/password login:
      // POST /auth/v1/token?grant_type=password
      const tokenResp = await fetch(`${supabaseUrlNoSlash}/auth/v1/token?grant_type=password`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'apikey': serviceKey,
          'Authorization': `Bearer ${serviceKey}`
        },
        body: JSON.stringify({ email, password })
      });

      // Try parse JSON; if parsing fails, fallback to text
      let tokenData = null;
      try {
        tokenData = await tokenResp.clone().json();
      } catch {
        try {
          tokenData = await tokenResp.clone().text();
        } catch {
          tokenData = null;
        }
      }

      if (!tokenResp.ok) {
        if (DEBUG) console.log('[login][token-error]', tokenResp.status, tokenData);
        return json({
          error: tokenData ?? { status: tokenResp.status }
        }, tokenResp.status === 200 ? 400 : tokenResp.status);
      }

      return json({
        user: tokenData?.user ?? null,
        session: tokenData
      }, 200);
    }

    // -------------------------------
    // POST /pns
    // Body: { user_id, token, platform?, device_info? }
    // Stores a push notification token row in public.pns
    // -------------------------------
    if (path === '/pns' && method === 'POST') {
      const body = await readJson(req);
      if (!body) return badRequest('Invalid or empty JSON');

      const { user_id, token, platform, device_info } = body;
      if (!user_id || !token) return badRequest('Missing required fields: user_id, token');

      const insertObj = {
        user_id,
        token
      };
      if (platform != null) insertObj.platform = String(platform);
      if (device_info != null) insertObj.device_info = String(device_info);

      if (DEBUG) console.log('[pns][POST] inserting', {
        user_id,
        tokenPrefix: String(token).slice(0, 8),
        hasPlatform: platform != null,
        hasDeviceInfo: device_info != null
      });

      const { data, error } = await db
        .from('pns')
        .insert(insertObj)
        .select('id,user_id,token,platform,device_info,is_active,created_at,last_used_at')
        .single();

      if (error) {
        if (DEBUG) console.log('[pns][POST][db-error]', error.message);
        return json({ error: error.message }, 400);
      }

      return json({ pns: data }, 201);
    }

    // -------------------------------
    // POST /notify
    // Body: { user_id, text }
    // Looks up all active device tokens for a user in public.pns, then calls Pushy API
    // -------------------------------
    if (path === '/notify' && method === 'POST') {
      const body = await readJson(req);
      if (!body) return badRequest('Invalid or empty JSON');

      const { user_id, text } = body;
      if (!user_id || !text) return badRequest('Missing required fields: user_id, text');

      const pushyKey = (Deno.env.get('PUSHY_SECRET_KEY') ?? '').trim();
      if (!pushyKey) {
        return json({ error: 'Server misconfig: missing PUSHY_SECRET_KEY' }, 500);
      }

      // Fetch active tokens for user
      const { data: rows, error: tErr } = await db
        .from('pns')
        .select('token')
        .eq('user_id', user_id)
        .eq('is_active', true);

      if (tErr) {
        if (DEBUG) console.log('[notify][tokens][db-error]', tErr.message);
        return json({ error: tErr.message }, 400);
      }

      const tokens = (rows ?? [])
        .map((r) => r?.token)
        .filter((t) => typeof t === 'string' && t.trim() !== '')
        .map((t) => t.trim());

      if (tokens.length === 0) {
        return json({ error: 'No active device tokens for user' }, 404);
      }
      if (tokens.length > 100000) {
        return json({ error: 'Too many device tokens (max 100000 per request)' }, 400);
      }

      if (DEBUG) console.log('[notify] sending', { user_id, tokens: tokens.length });

      // Pushy Send Notifications API
      const pushyResp = await fetch(`https://api.pushy.me/push?api_key=${encodeURIComponent(pushyKey)}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          to: tokens,
          data: { message: String(text) },
          notification: {
            title: 'Credit Card Fraud Detection',
            body: String(text)
          }
        })
      });

      let pushyData = null;
      try {
        pushyData = await pushyResp.clone().json();
      } catch {
        try {
          pushyData = await pushyResp.clone().text();
        } catch {
          pushyData = null;
        }
      }

      if (!pushyResp.ok) {
        if (DEBUG) console.log('[notify][pushy-error]', pushyResp.status, pushyData);
        return json({ error: pushyData ?? { status: pushyResp.status } }, pushyResp.status);
      }

      // Best-effort: update last_used_at for this user's active tokens
      const nowISO = new Date().toISOString();
      await db.from('pns').update({ last_used_at: nowISO }).eq('user_id', user_id).eq('is_active', true);

      return json({ pushy: pushyData }, 200);
    }

    // -------------------------------
    // existing routes below...
    // (dailyreport, transactions, user, creditcard, etc.)
    // -------------------------------
    // GET /dailyreport?startTime=<YYYY-MM-DDThh:mm:ssZ>&endTime=<YYYY-MM-DDThh:mm:ssZ>
    // Uses generated column "ts" (timestamptz) for range filtering
    if (path === '/dailyreport' && method === 'GET') {
      const startISO = url.searchParams.get('startTime');
      const endISO = url.searchParams.get('endTime');
      if (!startISO || !endISO) return badRequest('Missing startTime or endTime (ISO string expected)');
      const start = new Date(startISO);
      const end = new Date(endISO);
      if (isNaN(start.getTime()) || isNaN(end.getTime())) return badRequest('Invalid startTime or endTime');
      if (DEBUG) console.log('[dailyreport] ts range', {
        startISO,
        endISO
      });
      // Exclude userId & ccNumber; include ts so caller can see exact moment if useful
      const selectCols = 'ts,date,time,longitude,latitude,amount,created_at,fraud_flag,fraud_reason,fraud_checked_at,txn_id';
      const { data, error } = await db.from('Transactions') // case-sensitive quoted identifier
        .select(selectCols).eq('fraud_flag', true).gte('ts', start.toISOString()).lte('ts', end.toISOString()).order('ts', {
          ascending: true
        });
      if (error) {
        if (DEBUG) console.log('[dailyreport][db-error]', error.message);
        return json({
          error: error.message
        }, 400);
      }
      if (DEBUG) console.log('[dailyreport] rows', data?.length ?? 0);
      return json({
        report: data ?? []
      }, 200);
    }
    // GET /transactions  (requires header: user_id)
    if (path === '/transactions' && method === 'GET') {
      const userId = req.headers.get('user_id');
      if (!userId) return forbidden();
      if (DEBUG) console.log('[transactions][GET] user', userId);
      const { data, error } = await db.from('Transactions').select('*').eq('userId', userId).order('created_at', {
        ascending: false
      }).limit(100);
      if (error) {
        if (DEBUG) console.log('[transactions][GET][db-error]', error.message);
        return json({
          error: error.message
        }, 400);
      }
      if (DEBUG) console.log('[transactions][GET] rows', data?.length ?? 0);
      return json({
        transactions: data ?? []
      }, 200);
    }
    // POST /transactions
    if (path === '/transactions' && method === 'POST') {
      const body = await readJson(req);
      if (!body) return badRequest('Invalid or empty JSON');
      const { userId, ccNumber, date, time, longitude, latitude, amount, fraud_flag, fraud_reason } = body;
      if (!userId || !ccNumber || longitude == null || latitude == null || amount == null) {
        return badRequest('Missing required fields: userId, ccNumber, longitude, latitude, amount');
      }
      const insertObj = {
        userId,
        ccNumber,
        longitude,
        latitude,
        amount
      };
      if (date) insertObj.date = date;
      if (time) insertObj.time = time;
      if (typeof fraud_flag === 'boolean') insertObj.fraud_flag = fraud_flag;
      if (fraud_reason != null) insertObj.fraud_reason = String(fraud_reason);
      // NOTE: ts is generated; no need to set in insertObj.
      if (DEBUG) console.log('[transactions][POST] inserting', {
        userId,
        ccLast4: String(ccNumber).slice(-4),
        hasDate: !!date,
        hasTime: !!time,
        amount
      });
      const { data, error } = await db.from('Transactions').insert(insertObj).select('*').single();
      if (error) {
        if (DEBUG) console.log('[transactions][POST][db-error]', error.message);
        return json({
          error: error.message
        }, 400);
      }
      return json({
        transaction: data
      }, 201);
    }
    // GET /user  (requires header: user_id)
    if (path === '/user' && method === 'GET') {
      const userId = req.headers.get('user_id');
      if (!userId) return forbidden();
      if (DEBUG) console.log('[user][GET] user', userId);
      const [{ data: user, error: uErr }, { data: cards, error: cErr }] = await Promise.all([
        db.from('Users').select('id,name,isAdmin').eq('id', userId).single(),
        db.from('CreditCards').select('ccNumber,exp,iss,created_at').eq('userId', userId).order('created_at', {
          ascending: false
        })
      ]);
      if (uErr) {
        if (DEBUG) console.log('[user][GET][db-error:user]', uErr.message);
        return json({
          error: uErr.message
        }, 400);
      }
      if (!user) return notFound('User not found');
      if (cErr) {
        if (DEBUG) console.log('[user][GET][db-error:cards]', cErr.message);
        return json({
          error: cErr.message
        }, 400);
      }
      return json({
        user: {
          id: user.id,
          name: user.name,
          isAdmin: user.isAdmin,
          creditCards: cards ?? []
        }
      }, 200);
    }
    // PUT /transactions
    if (path === '/transactions' && method === 'PUT') {
      const body = await readJson(req);
      if (!body) return badRequest('Invalid or empty JSON');
      const { transactionId, fraud_flag, fraud_reason } = body;
      if (!transactionId || typeof fraud_flag !== 'boolean') {
        return badRequest('Missing required fields: transactionId (uuid), fraud_flag (boolean)');
      }
      const patch = {
        fraud_flag,
        fraud_checked_at: new Date().toISOString()
      };
      if (fraud_reason != null) patch.fraud_reason = String(fraud_reason);
      if (DEBUG) console.log('[transaction][PUT] updating', {
        transactionId,
        fraud_flag
      });
      const { data, error } = await db.from('Transactions').update(patch).eq('txn_id', transactionId).select('*').single();
      if (error) {
        if (DEBUG) console.log('[transaction][PUT][db-error]', error.message);
        return json({
          error: error.message
        }, 400);
      }
      return json({
        transaction: data
      }, 200);
    }
    // POST /creditcard
    if (path === '/creditcard' && method === 'POST') {
      const body = await readJson(req);
      if (!body) return badRequest('Invalid or empty JSON');
      const { userId, ccNumber, exp, sec, iss } = body;
      if (!userId || !ccNumber || !exp || !sec || !iss) {
        return badRequest('Missing required fields: userId, ccNumber, exp, sec, iss');
      }
      if (DEBUG) console.log('[creditcard][POST] inserting', {
        userId,
        ccLast4: String(ccNumber).slice(-4)
      });
      const { data, error } = await db.from('CreditCards').insert({
        userId,
        ccNumber,
        exp,
        sec,
        iss
      }).select('ccNumber,exp,iss,created_at').single();
      if (error) {
        if (DEBUG) console.log('[creditcard][POST][db-error]', error.message);
        return json({
          error: error.message
        }, 400);
      }
      return json({
        creditCard: data
      }, 201);
    }
    // Fallback
    return notFound('Route not found');
  } catch (error) {
    console.error('[edge] unhandled', {
      message: error?.message,
      stack: error?.stack
    });
    return json({
      error: error?.message ?? 'Internal Server Error'
    }, 500);
  }
});
