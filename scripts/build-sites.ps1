$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$fileList = @(
  'index.html',
  'nationwide_ports.generated.js',
  'bait_live.json',
  'tide_stations.json',
  'manifest.webmanifest',
  'sw.js',
  'icon-192.png',
  'icon-512.png',
  'icon-512-maskable.png',
  'apple-touch-icon-180.png',
  'og.png',
  'privacy.html',
  'terms.html',
  'support.html',
  'app-ads.txt',
  'assets/fish-species-sprite-v1.png'
)
$contentTypes = @{
  '.html' = 'text/html; charset=utf-8'
  '.webmanifest' = 'application/manifest+json; charset=utf-8'
  '.js' = 'text/javascript; charset=utf-8'
  '.json' = 'application/json; charset=utf-8'
  '.png' = 'image/png'
  '.txt' = 'text/plain; charset=utf-8'
}
$assetMap = [ordered]@{}
foreach ($fileName in $fileList) {
  $extension = [IO.Path]::GetExtension($fileName)
  $assetMap['/' + $fileName] = [ordered]@{
    type = $contentTypes[$extension]
    body = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $projectRoot $fileName)))
  }
}
$assetMap['/'] = $assetMap['/index.html']
$assetJson = $assetMap | ConvertTo-Json -Compress -Depth 4
$workerSource = @"
const assets=$assetJson;
const tideMemory=new Map();
const postRate=new Map();
let postsSchemaReady=false;
function decode(value){const raw=atob(value);const bytes=new Uint8Array(raw.length);for(let i=0;i<raw.length;i++)bytes[i]=raw.charCodeAt(i);return bytes;}
const corsHeaders={'access-control-allow-origin':'*','access-control-allow-methods':'GET, POST, DELETE, OPTIONS','access-control-allow-headers':'content-type, accept, x-owner-token','access-control-max-age':'86400'};
function jsonResponse(value,status=200){return new Response(JSON.stringify(value),{status,headers:{...corsHeaders,'content-type':'application/json; charset=utf-8','cache-control':'no-store','x-content-type-options':'nosniff'}});}
function textField(form,name,maxLength){return String(form.get(name)||'').trim().slice(0,maxLength);}
function optionalNumber(form,name,min,max){const raw=textField(form,name,20);if(!raw)return null;const value=Number(raw);return Number.isFinite(value)&&value>=min&&value<=max?value:null;}
async function ensurePostsSchema(env){
  if(postsSchemaReady)return;
  if(!env.DB)throw new Error('D1 unavailable');
  await env.DB.batch([
    env.DB.prepare('CREATE TABLE IF NOT EXISTS posts (id TEXT PRIMARY KEY NOT NULL, spot TEXT NOT NULL, species TEXT NOT NULL, catch_count INTEGER NOT NULL DEFAULT 0, max_size_cm REAL, method TEXT, memo TEXT, fishing_date TEXT NOT NULL, fishing_time TEXT, weather TEXT, wave_m REAL, depth_m REAL, photo_key TEXT, photo_type TEXT, author_id TEXT, owner_token_hash TEXT, hidden INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL)'),
    env.DB.prepare('CREATE INDEX IF NOT EXISTS idx_posts_created_at ON posts(created_at DESC)'),
    env.DB.prepare('CREATE TABLE IF NOT EXISTS post_reports (id TEXT PRIMARY KEY NOT NULL, post_id TEXT NOT NULL, reason TEXT NOT NULL, created_at TEXT NOT NULL)'),
    env.DB.prepare('CREATE INDEX IF NOT EXISTS idx_post_reports_post_id ON post_reports(post_id)'),
    env.DB.prepare('CREATE TABLE IF NOT EXISTS suspended_authors (author_id TEXT PRIMARY KEY NOT NULL, reason TEXT NOT NULL, created_at TEXT NOT NULL)'),
    env.DB.prepare('CREATE TABLE IF NOT EXISTS support_requests (id TEXT PRIMARY KEY NOT NULL, kind TEXT NOT NULL, reply TEXT, message TEXT NOT NULL, created_at TEXT NOT NULL)')
  ]);
  const columns=await env.DB.prepare('PRAGMA table_info(posts)').all(),names=new Set((columns.results||[]).map(x=>x.name));
  if(!names.has('author_id'))await env.DB.prepare('ALTER TABLE posts ADD COLUMN author_id TEXT').run();
  if(!names.has('owner_token_hash'))await env.DB.prepare('ALTER TABLE posts ADD COLUMN owner_token_hash TEXT').run();
  if(!names.has('hidden'))await env.DB.prepare('ALTER TABLE posts ADD COLUMN hidden INTEGER NOT NULL DEFAULT 0').run();
  postsSchemaReady=true;
}
async function sha256(value){const bytes=new TextEncoder().encode(value),hash=await crypto.subtle.digest('SHA-256',bytes);return [...new Uint8Array(hash)].map(x=>x.toString(16).padStart(2,'0')).join('');}
function cleanText(value){return String(value||'').replace(/[<>]/g,'').trim();}
function objectionable(value){return /(\u6b7b\u306d|\u6bba\u3059|\u88f8|\u30bb\u30c3\u30af\u30b9|\u63f4\u4ea4|\u5dee\u5225|fuck|porn)/i.test(String(value||''));}
async function tideResponse(request,url){
  const station=(url.searchParams.get('station')||'').toUpperCase();
  const year=Number(url.searchParams.get('year'));
  const currentYear=new Date().getUTCFullYear();
  if(!/^[A-Z0-9]{2}$/.test(station)||!Number.isInteger(year)||year<currentYear-2||year>currentYear+2)return new Response('Invalid tide request',{status:400});
  const memoryKey=station+'|'+year;
  const responseHeaders={...corsHeaders,'content-type':'text/plain; charset=utf-8','cache-control':'public, max-age=86400, s-maxage=86400, stale-while-revalidate=604800','x-data-source':'Japan Meteorological Agency','x-tide-year':String(year)};
  if(tideMemory.has(memoryKey))return new Response(tideMemory.get(memoryKey),{status:200,headers:responseHeaders});
  const upstream='https://www.data.jma.go.jp/kaiyou/data/db/tide/suisan/txt/'+year+'/'+station+'.txt';
  const source=await fetch(upstream,{headers:{accept:'text/plain'}});
  if(!source.ok)return new Response('Tide data unavailable',{status:source.status===404?404:502});
  const body=await source.text();
  if(!body.trim())return new Response('Tide data unavailable',{status:502});
  if(tideMemory.size>=64)tideMemory.delete(tideMemory.keys().next().value);
  tideMemory.set(memoryKey,body);
  return new Response(body,{status:200,headers:responseHeaders});
}
async function photoTileResponse(path){
  const match=path.match(/^\/api\/photo-tile\/(\d{1,2})\/(\d+)\/(\d+)\.(?:jpg|jpeg)$/);
  if(!match)return new Response('Invalid photo tile request',{status:400});
  const z=Number(match[1]),x=Number(match[2]),y=Number(match[3]),limit=2**z;
  if(z<2||z>18||x<0||y<0||x>=limit||y>=limit)return new Response('Invalid photo tile coordinates',{status:400});
  const sources=['seamlessphoto','ort'];
  for(const sourceName of sources){
    const upstream='https://cyberjapandata.gsi.go.jp/xyz/'+sourceName+'/'+z+'/'+x+'/'+y+'.jpg';
    try{
      const source=await fetch(upstream,{headers:{accept:'image/avif,image/webp,image/jpeg,image/*'}});
      if(!source.ok)continue;
      const headers=new Headers({...corsHeaders,'content-type':source.headers.get('content-type')||'image/jpeg','cache-control':'public, max-age=86400, s-maxage=86400','x-photo-source':'GSI '+sourceName,'x-content-type-options':'nosniff'});
      return new Response(source.body,{status:200,headers});
    }catch(error){}
  }
  return new Response('Aerial photo unavailable',{status:404,headers:{'cache-control':'public, max-age=900'}});
}
async function postsResponse(request,env){
  if(!env.DB)return jsonResponse({error:'POST_DB_NOT_READY'},503);
  await ensurePostsSchema(env);
  if(request.method==='GET'){
    const result=await env.DB.prepare('SELECT id, spot, species, catch_count, max_size_cm, method, memo, fishing_date, fishing_time, weather, wave_m, depth_m, photo_key, author_id, created_at FROM posts WHERE hidden = 0 ORDER BY created_at DESC LIMIT 30').all();
    return jsonResponse({posts:(result.results||[]).map(row=>({...row,photo_url:row.photo_key?'/api/post-photo/'+encodeURIComponent(row.id):null}))});
  }
  if(request.method!=='POST')return jsonResponse({error:'Method not allowed'},405);
  const ip=request.headers.get('cf-connecting-ip')||'unknown',now=Date.now(),recent=(postRate.get(ip)||[]).filter(t=>now-t<600000);
  if(recent.length>=6)return jsonResponse({error:'POST_RATE_LIMIT'},429);
  const form=await request.formData();
  if(textField(form,'website',80))return jsonResponse({error:'Invalid submission'},400);
  if(textField(form,'age_confirmed',1)!=='1'||textField(form,'terms_accepted',1)!=='1')return jsonResponse({error:'POST_TERMS_REQUIRED'},403);
  const authorId=/^[0-9a-f-]{36}$/i.test(textField(form,'author_id',36))?textField(form,'author_id',36):crypto.randomUUID();
  const suspended=await env.DB.prepare('SELECT author_id FROM suspended_authors WHERE author_id = ? LIMIT 1').bind(authorId).first();
  if(suspended)return jsonResponse({error:'POST_AUTHOR_SUSPENDED'},403);
  const spot=cleanText(textField(form,'spot',80)),species=cleanText(textField(form,'species',40)),date=textField(form,'date',10),time=textField(form,'time',5),weather=cleanText(textField(form,'weather',20)),method=cleanText(textField(form,'method',30)),memo=cleanText(textField(form,'memo',500));
  if(!spot||!species||!/^\d{4}-\d{2}-\d{2}$/.test(date))return jsonResponse({error:'POST_REQUIRED_FIELDS'},400);
  if(objectionable([spot,species,memo].join(' ')))return jsonResponse({error:'POST_REJECTED_CONTENT'},400);
  if(time&&!/^([01]\d|2[0-3]):[0-5]\d$/.test(time))return jsonResponse({error:'POST_INVALID_TIME'},400);
  const catchCount=optionalNumber(form,'count',0,999),maxSize=optionalNumber(form,'max_size_cm',0,300),wave=optionalNumber(form,'wave_m',0,30),depth=optionalNumber(form,'depth_m',0,2000);
  const photo=form.get('photo'),hasPhoto=photo&&typeof photo.arrayBuffer==='function'&&photo.size>0;
  const allowedTypes=['image/jpeg','image/png','image/webp','image/heic','image/heif'];
  if(hasPhoto&&(!allowedTypes.includes(photo.type)||photo.size>8*1024*1024))return jsonResponse({error:'POST_INVALID_PHOTO'},400);
  if(hasPhoto&&!env.UPLOADS)return jsonResponse({error:'POST_PHOTO_NOT_READY'},503);
  const id=crypto.randomUUID(),createdAt=new Date().toISOString(),photoKey=hasPhoto?'posts/'+id+'/photo':null,ownerToken=textField(form,'owner_token',100),ownerTokenHash=ownerToken?await sha256(ownerToken):null;
  if(hasPhoto)await env.UPLOADS.put(photoKey,await photo.arrayBuffer(),{httpMetadata:{contentType:photo.type},customMetadata:{postId:id}});
  try{
    await env.DB.prepare('INSERT INTO posts (id, spot, species, catch_count, max_size_cm, method, memo, fishing_date, fishing_time, weather, wave_m, depth_m, photo_key, photo_type, author_id, owner_token_hash, hidden, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?)').bind(id,spot,species,catchCount??0,maxSize,method||null,memo||null,date,time||null,weather||null,wave,depth,photoKey,hasPhoto?photo.type:null,authorId,ownerTokenHash,createdAt).run();
  }catch(error){if(photoKey&&env.UPLOADS)await env.UPLOADS.delete(photoKey);throw error;}
  recent.push(now);postRate.set(ip,recent);
  return jsonResponse({post:{id,spot,species,catch_count:catchCount??0,max_size_cm:maxSize,method,memo,fishing_date:date,fishing_time:time,weather,wave_m:wave,depth_m:depth,author_id:authorId,photo_url:photoKey?'/api/post-photo/'+encodeURIComponent(id):null,created_at:createdAt}},201);
}
async function postActionResponse(request,path,env){
  if(!env.DB)return jsonResponse({error:'POST_DB_NOT_READY'},503);await ensurePostsSchema(env);
  const match=path.match(/^\/api\/posts\/([0-9a-f-]{36})(?:\/report)?$/i);if(!match)return jsonResponse({error:'Not found'},404);const id=match[1];
  if(path.endsWith('/report')&&request.method==='POST'){
    const form=await request.formData(),reason=cleanText(textField(form,'reason',120))||'reported content';
    await env.DB.prepare('INSERT INTO post_reports (id, post_id, reason, created_at) VALUES (?, ?, ?, ?)').bind(crypto.randomUUID(),id,reason,new Date().toISOString()).run();
    const reported=await env.DB.prepare('SELECT author_id FROM posts WHERE id = ? LIMIT 1').bind(id).first();
    await env.DB.prepare('UPDATE posts SET hidden = 1 WHERE id = ?').bind(id).run();
    if(reported?.author_id){await env.DB.prepare('INSERT OR IGNORE INTO suspended_authors (author_id, reason, created_at) VALUES (?, ?, ?)').bind(reported.author_id,'User content report',new Date().toISOString()).run();await env.DB.prepare('UPDATE posts SET hidden = 1 WHERE author_id = ?').bind(reported.author_id).run();}
    await env.DB.prepare('INSERT INTO support_requests (id, kind, reply, message, created_at) VALUES (?, ?, ?, ?, ?)').bind(crypto.randomUUID(),'ugc_report_24h',null,'post_id: '+id+' / reason: '+reason,new Date().toISOString()).run();
    return jsonResponse({ok:true});
  }
  if(request.method==='DELETE'){
    const token=request.headers.get('x-owner-token')||'';if(!token)return jsonResponse({error:'DELETE_NOT_AUTHORIZED'},403);
    const row=await env.DB.prepare('SELECT photo_key, owner_token_hash FROM posts WHERE id = ? LIMIT 1').bind(id).first();if(!row||!row.owner_token_hash||await sha256(token)!==row.owner_token_hash)return jsonResponse({error:'DELETE_NOT_AUTHORIZED'},403);
    await env.DB.prepare('DELETE FROM posts WHERE id = ?').bind(id).run();if(row.photo_key&&env.UPLOADS)await env.UPLOADS.delete(row.photo_key);return jsonResponse({ok:true});
  }
  return jsonResponse({error:'Method not allowed'},405);
}
async function supportResponse(request,env){if(request.method!=='POST')return jsonResponse({error:'Method not allowed'},405);if(!env.DB)return jsonResponse({error:'Unavailable'},503);await ensurePostsSchema(env);const form=await request.formData();if(textField(form,'website',80))return jsonResponse({ok:true});const kind=cleanText(textField(form,'kind',40)),reply=cleanText(textField(form,'reply',160)),message=cleanText(textField(form,'message',2000));if(!message)return jsonResponse({error:'Required'},400);await env.DB.prepare('INSERT INTO support_requests (id, kind, reply, message, created_at) VALUES (?, ?, ?, ?, ?)').bind(crypto.randomUUID(),kind||'other',reply||null,message,new Date().toISOString()).run();return jsonResponse({ok:true},201);}
async function postPhotoResponse(path,env){
  if(!env.DB||!env.UPLOADS)return new Response('Photo storage unavailable',{status:503});
  await ensurePostsSchema(env);
  const id=decodeURIComponent(path.slice('/api/post-photo/'.length));
  if(!/^[0-9a-f-]{36}$/i.test(id))return new Response('Not found',{status:404});
  const row=await env.DB.prepare('SELECT photo_key, photo_type FROM posts WHERE id = ? AND hidden = 0 LIMIT 1').bind(id).first();
  if(!row||!row.photo_key)return new Response('Not found',{status:404});
  const object=await env.UPLOADS.get(row.photo_key);if(!object)return new Response('Not found',{status:404});
  return new Response(object.body,{headers:{...corsHeaders,'content-type':row.photo_type||'application/octet-stream','cache-control':'public, max-age=86400','x-content-type-options':'nosniff'}});
}
export default {async fetch(request,env){const url=new URL(request.url);let path=decodeURIComponent(url.pathname);if(request.method==='OPTIONS'&&path.startsWith('/api/'))return new Response(null,{status:204,headers:corsHeaders});if(path==='/api/tide')return tideResponse(request,url);if(path==='/api/posts')return postsResponse(request,env);if(path.startsWith('/api/posts/'))return postActionResponse(request,path,env);if(path==='/api/support')return supportResponse(request,env);if(path.startsWith('/api/post-photo/'))return postPhotoResponse(path,env);if(path.startsWith('/api/photo-tile/'))return photoTileResponse(path);if(path.endsWith('/'))path='/';const asset=assets[path]||(path.includes('.')?null:assets['/index.html']);if(!asset)return new Response('Not found',{status:404});const headers=new Headers({'content-type':asset.type,'x-content-type-options':'nosniff'});if(path==='/sw.js')headers.set('service-worker-allowed','/');if(path==='/index.html'||path==='/')headers.set('cache-control','no-cache');else headers.set('cache-control','public, max-age=3600');return new Response(decode(asset.body),{status:200,headers});}};
"@
$distPath = Join-Path $projectRoot 'dist'
if (Test-Path $distPath) {
  Remove-Item -LiteralPath $distPath -Recurse -Force
}
$serverPath = Join-Path $distPath 'server'
New-Item -ItemType Directory -Path $serverPath -Force | Out-Null
[IO.File]::WriteAllText((Join-Path $serverPath 'index.js'), $workerSource, [Text.UTF8Encoding]::new($false))
Get-Item (Join-Path $serverPath 'index.js') | Select-Object FullName, Length
