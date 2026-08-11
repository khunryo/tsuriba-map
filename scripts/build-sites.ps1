$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$fileList = @(
  'index.html',
  'bait_live.json',
  'tide_stations.json',
  'manifest.webmanifest',
  'sw.js',
  'icon-192.png',
  'icon-512.png',
  'icon-512-maskable.png',
  'apple-touch-icon-180.png',
  'og.png',
  'assets/fish-species-sprite-v1.png'
)
$contentTypes = @{
  '.html' = 'text/html; charset=utf-8'
  '.webmanifest' = 'application/manifest+json; charset=utf-8'
  '.js' = 'text/javascript; charset=utf-8'
  '.json' = 'application/json; charset=utf-8'
  '.png' = 'image/png'
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
function jsonResponse(value,status=200){return new Response(JSON.stringify(value),{status,headers:{'content-type':'application/json; charset=utf-8','cache-control':'no-store','x-content-type-options':'nosniff'}});}
function textField(form,name,maxLength){return String(form.get(name)||'').trim().slice(0,maxLength);}
function optionalNumber(form,name,min,max){const raw=textField(form,name,20);if(!raw)return null;const value=Number(raw);return Number.isFinite(value)&&value>=min&&value<=max?value:null;}
async function ensurePostsSchema(env){
  if(postsSchemaReady)return;
  if(!env.DB)throw new Error('D1 unavailable');
  await env.DB.batch([
    env.DB.prepare('CREATE TABLE IF NOT EXISTS posts (id TEXT PRIMARY KEY NOT NULL, spot TEXT NOT NULL, species TEXT NOT NULL, catch_count INTEGER NOT NULL DEFAULT 0, max_size_cm REAL, method TEXT, memo TEXT, fishing_date TEXT NOT NULL, fishing_time TEXT, weather TEXT, wave_m REAL, depth_m REAL, photo_key TEXT, photo_type TEXT, created_at TEXT NOT NULL)'),
    env.DB.prepare('CREATE INDEX IF NOT EXISTS idx_posts_created_at ON posts(created_at DESC)')
  ]);
  postsSchemaReady=true;
}
async function tideResponse(request,url){
  const station=(url.searchParams.get('station')||'').toUpperCase();
  const year=Number(url.searchParams.get('year'));
  const currentYear=new Date().getUTCFullYear();
  if(!/^[A-Z0-9]{2}$/.test(station)||!Number.isInteger(year)||year<currentYear-2||year>currentYear+2)return new Response('Invalid tide request',{status:400});
  const memoryKey=station+'|'+year;
  if(tideMemory.has(memoryKey))return new Response(tideMemory.get(memoryKey),{status:200,headers:{'content-type':'text/plain; charset=utf-8','cache-control':'public, max-age=21600','x-data-source':'Japan Meteorological Agency'}});
  const upstream='https://www.data.jma.go.jp/kaiyou/data/db/tide/suisan/txt/'+year+'/'+station+'.txt';
  const source=await fetch(upstream,{headers:{accept:'text/plain'}});
  if(!source.ok)return new Response('Tide data unavailable',{status:source.status===404?404:502});
  const body=await source.text();
  if(tideMemory.size>=64)tideMemory.delete(tideMemory.keys().next().value);
  tideMemory.set(memoryKey,body);
  const response=new Response(body,{status:200,headers:{'content-type':'text/plain; charset=utf-8','cache-control':'public, max-age=21600, s-maxage=21600','x-data-source':'Japan Meteorological Agency'}});
  return response;
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
      const headers=new Headers({'content-type':source.headers.get('content-type')||'image/jpeg','cache-control':'public, max-age=86400, s-maxage=86400','x-photo-source':'GSI '+sourceName,'x-content-type-options':'nosniff'});
      return new Response(source.body,{status:200,headers});
    }catch(error){}
  }
  return new Response('Aerial photo unavailable',{status:404,headers:{'cache-control':'public, max-age=900'}});
}
async function postsResponse(request,env){
  if(!env.DB)return jsonResponse({error:'POST_DB_NOT_READY'},503);
  await ensurePostsSchema(env);
  if(request.method==='GET'){
    const result=await env.DB.prepare('SELECT id, spot, species, catch_count, max_size_cm, method, memo, fishing_date, fishing_time, weather, wave_m, depth_m, photo_key, created_at FROM posts ORDER BY created_at DESC LIMIT 30').all();
    return jsonResponse({posts:(result.results||[]).map(row=>({...row,photo_url:row.photo_key?'/api/post-photo/'+encodeURIComponent(row.id):null}))});
  }
  if(request.method!=='POST')return jsonResponse({error:'Method not allowed'},405);
  const ip=request.headers.get('cf-connecting-ip')||'unknown',now=Date.now(),recent=(postRate.get(ip)||[]).filter(t=>now-t<600000);
  if(recent.length>=6)return jsonResponse({error:'POST_RATE_LIMIT'},429);
  const form=await request.formData();
  if(textField(form,'website',80))return jsonResponse({error:'Invalid submission'},400);
  const spot=textField(form,'spot',80),species=textField(form,'species',40),date=textField(form,'date',10),time=textField(form,'time',5),weather=textField(form,'weather',20),method=textField(form,'method',30),memo=textField(form,'memo',500);
  if(!spot||!species||!/^\d{4}-\d{2}-\d{2}$/.test(date))return jsonResponse({error:'POST_REQUIRED_FIELDS'},400);
  if(time&&!/^([01]\d|2[0-3]):[0-5]\d$/.test(time))return jsonResponse({error:'POST_INVALID_TIME'},400);
  const catchCount=optionalNumber(form,'count',0,999),maxSize=optionalNumber(form,'max_size_cm',0,300),wave=optionalNumber(form,'wave_m',0,30),depth=optionalNumber(form,'depth_m',0,2000);
  const photo=form.get('photo'),hasPhoto=photo&&typeof photo.arrayBuffer==='function'&&photo.size>0;
  const allowedTypes=['image/jpeg','image/png','image/webp','image/heic','image/heif'];
  if(hasPhoto&&(!allowedTypes.includes(photo.type)||photo.size>8*1024*1024))return jsonResponse({error:'POST_INVALID_PHOTO'},400);
  if(hasPhoto&&!env.UPLOADS)return jsonResponse({error:'POST_PHOTO_NOT_READY'},503);
  const id=crypto.randomUUID(),createdAt=new Date().toISOString(),photoKey=hasPhoto?'posts/'+id+'/photo':null;
  if(hasPhoto)await env.UPLOADS.put(photoKey,await photo.arrayBuffer(),{httpMetadata:{contentType:photo.type},customMetadata:{postId:id}});
  try{
    await env.DB.prepare('INSERT INTO posts (id, spot, species, catch_count, max_size_cm, method, memo, fishing_date, fishing_time, weather, wave_m, depth_m, photo_key, photo_type, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)').bind(id,spot,species,catchCount??0,maxSize,method||null,memo||null,date,time||null,weather||null,wave,depth,photoKey,hasPhoto?photo.type:null,createdAt).run();
  }catch(error){if(photoKey&&env.UPLOADS)await env.UPLOADS.delete(photoKey);throw error;}
  recent.push(now);postRate.set(ip,recent);
  return jsonResponse({post:{id,spot,species,catch_count:catchCount??0,max_size_cm:maxSize,method,memo,fishing_date:date,fishing_time:time,weather,wave_m:wave,depth_m:depth,photo_url:photoKey?'/api/post-photo/'+encodeURIComponent(id):null,created_at:createdAt}},201);
}
async function postPhotoResponse(path,env){
  if(!env.DB||!env.UPLOADS)return new Response('Photo storage unavailable',{status:503});
  await ensurePostsSchema(env);
  const id=decodeURIComponent(path.slice('/api/post-photo/'.length));
  if(!/^[0-9a-f-]{36}$/i.test(id))return new Response('Not found',{status:404});
  const row=await env.DB.prepare('SELECT photo_key, photo_type FROM posts WHERE id = ? LIMIT 1').bind(id).first();
  if(!row||!row.photo_key)return new Response('Not found',{status:404});
  const object=await env.UPLOADS.get(row.photo_key);if(!object)return new Response('Not found',{status:404});
  return new Response(object.body,{headers:{'content-type':row.photo_type||'application/octet-stream','cache-control':'public, max-age=86400','x-content-type-options':'nosniff'}});
}
export default {async fetch(request,env){const url=new URL(request.url);let path=decodeURIComponent(url.pathname);if(path==='/api/tide')return tideResponse(request,url);if(path==='/api/posts')return postsResponse(request,env);if(path.startsWith('/api/post-photo/'))return postPhotoResponse(path,env);if(path.startsWith('/api/photo-tile/'))return photoTileResponse(path);if(path.endsWith('/'))path='/';const asset=assets[path]||(path.includes('.')?null:assets['/index.html']);if(!asset)return new Response('Not found',{status:404});const headers=new Headers({'content-type':asset.type,'x-content-type-options':'nosniff'});if(path==='/sw.js')headers.set('service-worker-allowed','/');if(path==='/index.html'||path==='/')headers.set('cache-control','no-cache');else headers.set('cache-control','public, max-age=3600');return new Response(decode(asset.body),{status:200,headers});}};
"@
$distPath = Join-Path $projectRoot 'dist'
if (Test-Path $distPath) {
  Remove-Item -LiteralPath $distPath -Recurse -Force
}
$serverPath = Join-Path $distPath 'server'
New-Item -ItemType Directory -Path $serverPath -Force | Out-Null
[IO.File]::WriteAllText((Join-Path $serverPath 'index.js'), $workerSource, [Text.UTF8Encoding]::new($false))
Get-Item (Join-Path $serverPath 'index.js') | Select-Object FullName, Length
