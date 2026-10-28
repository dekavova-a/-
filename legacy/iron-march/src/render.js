(function(root){
'use strict';
const {WIDTH,HEIGHT,CELL,COLS,ROWS,TYPES,clamp}=Iron, SY=.66;
function rng(seed){return()=>{seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed/4294967296;};}
function polygon(c,pts,fill,stroke){c.beginPath();pts.forEach((p,i)=>i?c.lineTo(p[0],p[1]):c.moveTo(p[0],p[1]));c.closePath();if(fill){c.fillStyle=fill;c.fill();}if(stroke){c.strokeStyle=stroke;c.stroke();}}
function vehicle(ctx,u,scale=1,time=0){
 const team=u.team?'#c77c49':'#5e9cae',light=u.team?'#ecb175':'#a5c9ce',dark=u.team?'#75452e':'#365e69';let angle=u.angle||0;
 const P=(x,y,z=0)=>{const ca=Math.cos(angle),sa=Math.sin(angle);return [(x*ca-y*sa)*scale,((x*sa+y*ca)*SY-z)*scale];};
 const poly=(pts,color,stroke)=>polygon(ctx,pts.map(p=>P(...p)),color,stroke);
 function box(x,y,w,h,z,d,color=team){const a=[[x-w/2,y-h/2,z],[x+w/2,y-h/2,z],[x+w/2,y+h/2,z],[x-w/2,y+h/2,z]],b=a.map(p=>[p[0],p[1],p[2]+d]);poly([a[0],a[1],b[1],b[0]],dark);poly([a[1],a[2],b[2],b[1]],'#243234');poly([a[2],a[3],b[3],b[2]],dark);poly([a[3],a[0],b[0],b[3]],'#263539');poly(b,color,'#162529');}
 function line(x,y,z,x2,y2,z2,color,width=1){const a=P(x,y,z),b=P(x2,y2,z2);ctx.strokeStyle=color;ctx.lineWidth=width*scale;ctx.beginPath();ctx.moveTo(...a);ctx.lineTo(...b);ctx.stroke();}
 function wheels(len,y,big=false){box(0,y,len,big?18:10,1,big?17:8,'#222d2b');const n=big?9:5;for(let i=0;i<n;i++){const x=-len/2+5+i*(len-10)/(n-1);box(x,y,len/n-2,big?19:11,2,big?15:7,i%2?'#414a43':'#303a35');line(x,y-(big?9:5),big?18:10,x+2,y+(big?9:5),big?18:10,'#667067',.8);}if(u.moving){for(let i=0;i<n;i++){const x=-len/2+((i*len/n+u.travel)%len);line(x,y-5,11,x,y+5,11,'#8a9689',1);}}}
 ctx.save();ctx.globalAlpha=.35;const shadow=ctx.createRadialGradient(5,7,0,5,7,u.type==='base'?130*scale:42*scale);shadow.addColorStop(0,'#111812');shadow.addColorStop(1,'#11181200');ctx.fillStyle=shadow;ctx.beginPath();ctx.ellipse(7*scale,9*scale,u.type==='base'?135*scale:42*scale,u.type==='base'?72*scale:23*scale,0,0,Math.PI*2);ctx.fill();ctx.restore();
 if(u.type==='base'){
  const d=u.deployed||0;wheels(150,-48,true);wheels(150,48,true);box(-5,0,142,86,17,26,'#596a63');box(-7,0,122,72,43,24,team);
  for(const side of [-1,1]){box(-8,side*(53+d*40),100,32,10,20,d>.1?'#566660':team);box(-8,side*(53+d*40),85,24,30,4,'#83938a');for(let i=-2;i<=2;i++)line(i*17-8,side*(53+d*40)-10,35,i*17-8,side*(53+d*40)+10,35,'#394e4b',2);if(d>.2){box(-45,side*(65+d*42),10,12,0,25,'#7f8170');box(40,side*(65+d*42),10,12,0,25,'#7f8170');line(-40,side*40,37,-40,side*(52+d*40),32,'#d4ad74',3);}}
  box(-38,0,38,49,67,14,'#89998e');box(35,-6,39,45,66,20,'#c1bca0');box(49,-6,15,36,86,6,'#697c74');box(58,-9,2,27,92,2,light);box(62,0,22,50,24,12,'#777e6a');
  for(let i=0;i<5;i++)box(-58+i*10,15,6,18,82,2,'#283d3c');
  box(-43,-17,15,14,81,22,'#505c52');box(-43,-17,19,18,103,4,'#2e3934');line(-42,-17,105,-42,-17,119,'#969888',2);
  box(0,-15,24,28,68,8,'#3f5653');box(0,-15,14,15,76,8,team);
  line(-10,-15,85,22,-15,85,'#d8bc83',5);line(-7,-28,68,-7,-28,110,'#bec1a6',2);line(-20,-28,102,7,-28,114,'#647f77',3);
  for(let s of [-1,1]){line(65,s*30,38,68,s*30,38,'#f4d398',4);box(20,s*29,24,4,69,1,light);}
  if(d>.5){for(let i=0;i<4;i++)box(86+i*6,0,5,33-i*3,2,2,'#4b5548');box(72,0,6,40,3,2,'#c6a277');}
 }else if(u.type==='turret'){
  box(0,0,56,50,0,8,'#6a6d58');box(0,0,32,30,8,29,'#7a8070');angle=u.turret||0;box(-3,0,34,24,37,11,team);box(24,-6,35,5,43,5,'#b0aa89');box(24,6,35,5,43,5,'#b0aa89');box(-7,0,13,14,48,5,light);
 }else{
  const small=u.type==='scout',eng=u.type==='engineer';const len=small?31:u.type==='artillery'?54:44,w=small?10:16;
  wheels(len,-w);wheels(len,w);box(0,0,len-3,w*2-6,9,8,team);box(-6,0,len*.56,w*1.3,17,6,'#a1a68e');box(len*.3,0,11,w*1.5,14,5,team);
  for(let i=0;i<3;i++)line(-len*.4+i*4,-6,24,-len*.4+i*4,6,24,'#354640',1.5);
  line(len/2,-w*.65,17,len/2,-w*.65+3,17,'#ffe2a3',2);line(len/2,w*.65-3,17,len/2,w*.65,17,'#ffe2a3',2);
  if(eng){box(1,0,16,17,23,9,'#cfaa66');line(4,0,33,24,0,43,'#d3ba81',4);line(24,0,43,31,0,22,'#677a6a',3);box(-13,0,12,22,23,5,'#3c514b');if(u.cargo>0)for(let i=0;i<3;i++)box(-13+i*3,0,3,14,29,Math.min(8,u.cargo/5),'#c4ba94');}
  else{angle=u.turret??u.angle;const arty=u.type==='artillery',rocket=u.type==='rocket';box(-2,0,small?12:22,small?12:21,23,small?6:10,team);box(-4,0,9,12,33,3,light);
   if(rocket){for(let s of [-1,1]){box(7,s*10,25,8,30,9,'#666f5a');for(let j=0;j<3;j++)box(20,s*10-3+j*3,2,2,34,3,'#222f2b');}}
   else {box((arty?27:22)-u.recoil*4,0,arty?49:small?20:32,arty?7:5,small?27:30,5,'#a7ad94');box(arty?49:small?28:38,0,6,arty?11:7,30,5,'#384c47');}
   if(u.flash>0){const p=P(rocket?23:arty?54:small?30:43,0,33);ctx.fillStyle='#ffe8ae';ctx.beginPath();ctx.arc(p[0],p[1],(rocket?8:12)*scale,0,7);ctx.fill();ctx.fillStyle='#fff9dc';ctx.beginPath();ctx.arc(p[0],p[1],4*scale,0,7);ctx.fill();}
  }
 }
 if(u.hit>0){ctx.globalCompositeOperation='screen';ctx.fillStyle='#ffc78365';ctx.beginPath();ctx.ellipse(0,-12*scale,32*scale,19*scale,0,0,7);ctx.fill();ctx.globalCompositeOperation='source-over';}
}
class Renderer{
 constructor(canvas,game){this.canvas=canvas;this.ctx=canvas.getContext('2d',{alpha:false});this.game=game;this.w=0;this.h=0;this.cam={x:650,y:930,zoom:.85};this.selected=new Set([game.base.id]);this.drag=null;this.markers=[];this.rocks=[];this.dust=[];this.makeTerrain();this.fogCanvas=document.createElement('canvas');this.fogCanvas.width=COLS;this.fogCanvas.height=ROWS;this.fogCtx=this.fogCanvas.getContext('2d');this.lastFog=-1;this.resize();}
 resize(){this.w=innerWidth;this.h=innerHeight;const dpr=Math.min(devicePixelRatio||1,1.75);this.dpr=dpr;this.canvas.width=Math.round(this.w*dpr);this.canvas.height=Math.round(this.h*dpr);this.ctx.setTransform(dpr,0,0,dpr,0,0);}
 screen(x,y,z=0){return {x:(x-this.cam.x)*this.cam.zoom+this.w/2,y:(y-this.cam.y)*SY*this.cam.zoom+this.viewCenter()-z*this.cam.zoom};}
 world(x,y){return{x:(x-this.w/2)/this.cam.zoom+this.cam.x,y:(y-this.viewCenter())/(SY*this.cam.zoom)+this.cam.y};}
 viewCenter(){return (this.h-230+85)/2;}
 center(u){this.cam.x=u.x;this.cam.y=u.y;}
 makeTerrain(){const r=rng(42);this.terrain=document.createElement('canvas');this.terrain.width=WIDTH;this.terrain.height=HEIGHT*SY+160;const c=this.terrain.getContext('2d');c.translate(0,110);c.scale(1,SY);const gr=c.createLinearGradient(0,0,WIDTH,HEIGHT);gr.addColorStop(0,'#8c6e4e');gr.addColorStop(.45,'#b28c5c');gr.addColorStop(1,'#84634b');c.fillStyle=gr;c.fillRect(0,-170,WIDTH,HEIGHT+340);
  for(let i=0;i<30000;i++){const x=r()*WIDTH,y=r()*HEIGHT;c.fillStyle=i%2?'#e2b97a20':'#2d302217';c.fillRect(x,y,1+r()*4,1+r()*2);}
  function road(points){for(const [width,color]of [[158,'#68513d35'],[122,'#cfaa7335'],[90,'#d1aa7230'],[3,'#7f654229']]){c.strokeStyle=color;c.lineWidth=width;c.lineCap='round';c.lineJoin='round';c.beginPath();points.forEach(([x,y],i)=>i?c.lineTo(x,y):c.moveTo(x,y));c.stroke();}for(let offset of [-24,24]){c.strokeStyle='#765e3d35';c.lineWidth=4;c.beginPath();points.forEach(([x,y],i)=>i?c.lineTo(x,y+offset):c.moveTo(x,y+offset));c.stroke();}}
  road([[250,1000],[550,800],[800,480],[1300,430],[1800,570],[2180,310]]);road([[350,1000],[750,1450],[1200,1490],[1600,1330],[2040,1100],[2180,310]]);
  for(let j=0;j<ROWS;j++)for(let i=0;i<COLS;i++)if(this.game.blocks[j*COLS+i]){const x=(i+.5)*CELL,y=(j+.5)*CELL;this.rocks.push({x,y,h:36+r()*62,size:34+r()*17,seed:r()*1000});c.fillStyle='#4e382d40';c.beginPath();c.ellipse(x+23,y+26,55,40,0,0,7);c.fill();}
  for(let i=0;i<170;i++){const x=r()*WIDTH,y=r()*HEIGHT;if(this.game.blocks[Math.floor(y/CELL)*COLS+Math.floor(x/CELL)])continue;const s=3+r()*10;c.fillStyle='#5c514040';c.beginPath();c.ellipse(x+3,y+3,s+2,s*.6,0,0,7);c.fill();polygon(c,[[x-s,y],[x-s*.4,y-s*.5],[x+s*.6,y-s*.5],[x+s,y],[x+s*.3,y+s*.4]],i%2?'#91856a':'#a59672');}
  // Abandoned industrial traces, tire tracks and reinforced pads.
  for(const [x,y]of [[750,380],[1780,1140],[2060,160],[340,940]]){c.save();c.translate(x,y);c.rotate(-.13);c.fillStyle='#7774636e';c.fillRect(-90,-70,180,140);c.strokeStyle='#4c544848';c.lineWidth=2;for(let j=-60;j<70;j+=25){c.beginPath();c.moveTo(-80,j);c.lineTo(80,j);c.stroke();}for(let i=-75;i<90;i+=30){c.beginPath();c.moveTo(i,-65);c.lineTo(i,65);c.stroke();}c.restore();}
  c.strokeStyle='#5e5c4b';c.lineWidth=12;c.beginPath();c.moveTo(110,1700);c.lineTo(550,1700);c.lineTo(650,1570);c.stroke();c.strokeStyle='#92917a';c.lineWidth=6;c.stroke();
 }
 rock(c,rock,p){const r=rng(Math.floor(rock.seed)),n=7,pts=[];for(let i=0;i<n;i++){const a=i/n*Math.PI*2,rad=rock.size*(.75+r()*.35);pts.push([Math.cos(a)*rad,Math.sin(a)*rad*SY]);}const h=rock.h;c.save();c.translate(p.x,p.y);c.scale(this.cam.zoom,this.cam.zoom);const top=pts.map(([x,y])=>[x*.8-5,y*.8-h]);for(let i=0;i<n;i++){const j=(i+1)%n;polygon(c,[pts[i],pts[j],top[j],top[i]],['#76513b','#80583f','#926647','#a0714b','#714a37','#674836','#845b3f'][i]);}polygon(c,top,'#aa8158');polygon(c,[top[0],top[1],[-4,-h+1],top[5]],'#bf9666');c.strokeStyle='#704d3570';c.lineWidth=1;for(let i=0;i<3;i++){c.beginPath();c.moveTo(-rock.size*.65,6-i*12);c.lineTo(rock.size*.55,-i*10);c.stroke();}c.restore();}
 resource(c,r,p){const rand=rng(r.id*235);c.save();c.translate(p.x,p.y);c.scale(this.cam.zoom,this.cam.zoom);c.fillStyle='#4c432b40';c.beginPath();c.ellipse(0,9,48,22,0,0,7);c.fill();const n=r.scrap?6:17;for(let i=0;i<n;i++){const x=(rand()-.5)*65,y=(rand()-.5)*35,s=5+rand()*12;polygon(c,[[x-s,y],[x,y-s],[x+s,y-4],[x+s*.5,y+s*.5]],i%3?'#9d9d82':'#c0b99a');polygon(c,[[x-s,y],[x,y-s],[x-2,y+3]],'#e1cba3');c.strokeStyle='#4e625c';c.strokeRect(x-3,y-3,s,3);}
  if(!r.scrap){c.strokeStyle='#e0bc7f';c.lineWidth=1;c.setLineDash([3,4]);c.beginPath();c.ellipse(0,0,53,29,0,0,7);c.stroke();c.setLineDash([]);c.fillStyle='#eee0c1';c.font='10px Segoe UI';c.textAlign='center';c.fillText(Math.ceil(r.amount)+' Fe',0,43);}c.restore();}
 draw(time){const c=this.ctx,g=this.game,z=this.cam.zoom;c.setTransform(this.dpr,0,0,this.dpr,0,0);c.fillStyle='#242923';c.fillRect(0,0,this.w,this.h);const origin=this.screen(0,0);c.drawImage(this.terrain,origin.x,origin.y-110*z,WIDTH*z,this.terrain.height*z);
  // Landmark is deliberately visible before scouting to orient the player.
  const goal=this.screen(g.goal.x,g.goal.y);c.save();c.translate(goal.x,goal.y);c.scale(z,z);c.strokeStyle='#e5b366';c.lineWidth=2;c.setLineDash([10,7]);c.beginPath();c.ellipse(0,0,g.goal.radius,g.goal.radius*SY,0,0,7);c.stroke();c.setLineDash([]);c.fillStyle='#edc586';c.font='11px Segoe UI';c.textAlign='center';c.fillText('ПЕРЕВАЛ / ЭВАКУАЦИЯ',0,-115);c.restore();
  const nodes=[];for(const rock of this.rocks){const p=this.screen(rock.x,rock.y);if(p.x>-100&&p.x<this.w+100&&p.y>-150&&p.y<this.h+150)nodes.push({y:rock.y,draw:()=>this.rock(c,rock,p)});}
  for(const r of g.resources){if(r.amount<.1||!g.fog[Math.floor(r.y/CELL)*COLS+Math.floor(r.x/CELL)])continue;const p=this.screen(r.x,r.y);if(p.x>-80&&p.x<this.w+80&&p.y>0&&p.y<this.h)nodes.push({y:r.y,draw:()=>this.resource(c,r,p)});}
  for(const u of g.units){if(u.hp<=0||!g.isVisible(u))continue;const p=this.screen(u.x,u.y);if(p.x<-180||p.x>this.w+180||p.y<-150||p.y>this.h+150)continue;nodes.push({y:u.y,draw:()=>{if(this.selected.has(u.id)){c.strokeStyle='#a5d9e0';c.lineWidth=1.5;c.beginPath();c.ellipse(p.x,p.y+4*z,(TYPES[u.type].radius+12)*z,(TYPES[u.type].radius+12)*SY*z,0,0,7);c.stroke();}c.save();c.translate(p.x,p.y);vehicle(c,u,z,time);c.restore();if(this.selected.has(u.id)||u.hp<u.maxHp){const width=u.type==='base'?94:34,yy=p.y-(u.type==='base'?118:48)*z;c.fillStyle='#17282b';c.fillRect(p.x-width*z/2-1,yy-1,width*z+2,5);c.fillStyle=u.team?'#e69865':'#97c0b1';c.fillRect(p.x-width*z/2,yy,width*z*u.hp/u.maxHp,3);}
    if(u.type==='engineer'&&(u.order==='mine'||u.order==='repair')&&!u.moving&&g.started&&!g.paused){const t=g.resources.find(r=>r.id===u.target)||g.units.find(v=>v.id===u.target);if(t){const tp=this.screen(t.x,t.y,8);c.strokeStyle=u.order==='repair'?'#acd4b1':'#fbd59b';c.lineWidth=1.5;c.beginPath();c.moveTo(p.x,p.y-17*z);c.lineTo(tp.x+Math.sin(time*22)*7,tp.y);c.stroke();}}
    if(u.moving){const rand=rng(u.id+Math.floor(time*7));for(let i=0;i<4;i++){c.fillStyle='#e1c28a18';c.beginPath();c.ellipse(p.x-Math.cos(u.angle)*(20+i*10)*z+(rand()-.5)*10,p.y-Math.sin(u.angle)*(15+i*6)*z+7*z,(9+i*4)*z,(4+i*2)*z,0,0,7);c.fill();}}
   }});}
  nodes.sort((a,b)=>a.y-b.y);for(const n of nodes)n.draw();
  // Fog is one tiny texture, smoothly enlarged rather than thousands of per-frame paths.
  if(this.lastFog!==Math.floor(g.time*5)){this.lastFog=Math.floor(g.time*5);const fc=this.fogCtx;fc.clearRect(0,0,COLS,ROWS);for(let k=0;k<COLS*ROWS;k++){fc.fillStyle=g.visible[k]?'#111d2100':g.fog[k]?'#111d2175':'#111d21dd';fc.fillRect(k%COLS,Math.floor(k/COLS),1,1);}}
  c.imageSmoothingEnabled=true;c.drawImage(this.fogCanvas,origin.x,origin.y,WIDTH*z,HEIGHT*SY*z);
  // Highlight only friendly paths. No enemy information leaks through fog.
  for(const u of g.units){if(!this.selected.has(u.id)||!u.path.length)continue;c.strokeStyle='#c5d7b65c';c.setLineDash([4,7]);c.lineWidth=1;c.beginPath();const p=this.screen(u.x,u.y);c.moveTo(p.x,p.y);for(const point of u.path){const q=this.screen(point.x,point.y);c.lineTo(q.x,q.y);}c.stroke();c.setLineDash([]);}
  for(const p of g.projectiles){const k=clamp(Math.floor(p.y/CELL),0,ROWS-1)*COLS+clamp(Math.floor(p.x/CELL),0,COLS-1);if(!g.visible[k])continue;const a=this.screen(p.x,p.y,18),angle=Math.atan2(p.ty-p.y,p.tx-p.x);c.strokeStyle=p.type==='rocket'?'#f7c89e':'#ffe1a4';c.lineWidth=p.type==='artillery'?3:2;c.beginPath();c.moveTo(a.x,a.y);c.lineTo(a.x-Math.cos(angle)*18*z,a.y-Math.sin(angle)*12*z);c.stroke();if(p.type==='rocket'){c.fillStyle='#ffdeb7';c.beginPath();c.arc(a.x,a.y,3*z,0,7);c.fill();}}
  for(const e of g.effects){if(!g.visible[Math.floor(e.y/CELL)*COLS+Math.floor(e.x/CELL)])continue;const p=this.screen(e.x,e.y),t=e.age/e.life;c.save();c.translate(p.x,p.y);c.globalAlpha=1-t;const rr=e.size*z;const grad=c.createRadialGradient(0,-rr*t*.7,0,0,-rr*t*.7,Math.max(1,rr*(.15+t)));grad.addColorStop(0,t<.25?'#fff2c7':'#9d7454');grad.addColorStop(.3,t<.3?'#f2a65e':'#776956');grad.addColorStop(1,'#5e594800');c.fillStyle=grad;c.beginPath();c.arc(0,-rr*t*.7,rr*(.15+t),0,7);c.fill();c.strokeStyle='#e7c89b';c.lineWidth=1;c.beginPath();c.ellipse(0,0,rr*t*1.5,rr*t*.75,0,0,7);c.stroke();c.restore();}
  const beacon=this.screen(g.goal.x,g.goal.y);c.save();c.globalAlpha=.7;c.strokeStyle='#efc784';c.lineWidth=2;c.beginPath();c.moveTo(beacon.x,beacon.y);c.lineTo(beacon.x,beacon.y-75*z);c.stroke();c.fillStyle='#ffdda0';c.beginPath();c.arc(beacon.x,beacon.y-75*z,4+Math.sin(time*3),0,7);c.fill();c.restore();
  for(const m of this.markers){const age=time-m.time;if(age>1)continue;const p=this.screen(m.x,m.y);c.strokeStyle=m.attack?'#e7a376':'#b6d8c6';c.globalAlpha=1-age;c.lineWidth=2;c.beginPath();c.ellipse(p.x,p.y,(12+age*22)*z,(8+age*14)*z,0,0,7);c.stroke();}c.globalAlpha=1;this.markers=this.markers.filter(m=>time-m.time<1);
  if(this.drag){const {x,y,ex,ey}=this.drag;c.fillStyle='#a4cfd013';c.strokeStyle='#b7dfe1';c.lineWidth=1;c.fillRect(x,y,ex-x,ey-y);c.strokeRect(x,y,ex-x,ey-y);}
  const vignette=c.createRadialGradient(this.w/2,this.h/2,this.h*.25,this.w/2,this.h/2,this.w*.7);vignette.addColorStop(0,'#00000000');vignette.addColorStop(1,'#0d191a50');c.fillStyle=vignette;c.fillRect(0,85,this.w,this.h-300);
 }
 minimap(canvas){const c=canvas.getContext('2d'),g=this.game,w=canvas.width,h=canvas.height,sx=w/WIDTH,sy=h/HEIGHT;c.fillStyle='#333c36';c.fillRect(0,0,w,h);for(let j=0;j<ROWS;j++)for(let i=0;i<COLS;i++){const k=j*COLS+i;c.fillStyle=!g.fog[k]?'#172226':g.blocks[k]?'#725743':g.visible[k]?'#a1855d':'#555747';c.fillRect(i*w/COLS,j*h/ROWS,w/COLS+.5,h/ROWS+.5);}for(const r of g.resources)if(r.amount>0&&g.fog[Math.floor(r.y/CELL)*COLS+Math.floor(r.x/CELL)]){c.fillStyle='#d5bf84';c.fillRect(r.x*sx-1,r.y*sy-1,3,3);}for(const u of g.units){if(u.hp<=0||!g.isVisible(u))continue;c.fillStyle=u.team?'#e79860':'#9bced2';const size=u.type==='base'?6:3;c.fillRect(u.x*sx-size/2,u.y*sy-size/2,size,size);}c.strokeStyle='#ebc481';c.strokeRect(g.goal.x*sx-5,g.goal.y*sy-4,10,8);const a=this.world(0,85),b=this.world(this.w,this.h-240);c.strokeStyle='#d1d9c5';c.lineWidth=1;c.strokeRect(a.x*sx,a.y*sy,(b.x-a.x)*sx,(b.y-a.y)*sy);}
}
root.IronRender={Renderer,vehicle,SY};
})(globalThis);
