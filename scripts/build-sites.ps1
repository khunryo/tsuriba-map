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
function decode(value){const raw=atob(value);const bytes=new Uint8Array(raw.length);for(let i=0;i<raw.length;i++)bytes[i]=raw.charCodeAt(i);return bytes;}
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
export default {async fetch(request){const url=new URL(request.url);let path=decodeURIComponent(url.pathname);if(path==='/api/tide')return tideResponse(request,url);if(path.startsWith('/api/photo-tile/'))return photoTileResponse(path);if(path.endsWith('/'))path='/';const asset=assets[path]||(path.includes('.')?null:assets['/index.html']);if(!asset)return new Response('Not found',{status:404});const headers=new Headers({'content-type':asset.type,'x-content-type-options':'nosniff'});if(path==='/sw.js')headers.set('service-worker-allowed','/');if(path==='/index.html'||path==='/')headers.set('cache-control','no-cache');else headers.set('cache-control','public, max-age=3600');return new Response(decode(asset.body),{status:200,headers});}};
"@
$distPath = Join-Path $projectRoot 'dist'
if (Test-Path $distPath) {
  Remove-Item -LiteralPath $distPath -Recurse -Force
}
$serverPath = Join-Path $distPath 'server'
New-Item -ItemType Directory -Path $serverPath -Force | Out-Null
[IO.File]::WriteAllText((Join-Path $serverPath 'index.js'), $workerSource, [Text.UTF8Encoding]::new($false))
Get-Item (Join-Path $serverPath 'index.js') | Select-Object FullName, Length
