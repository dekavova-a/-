(function (root) {
'use strict';
const CELL=50, COLS=48, ROWS=36, WIDTH=CELL*COLS, HEIGHT=CELL*ROWS;
const TYPES={
 base:{name:'Мобильный завод',role:'КОМАНДНЫЙ ЦЕНТР',hp:2400,speed:57,radius:47,range:240,damage:18,reload:1.2,vision:420},
 scout:{name:'Разведчик',role:'ОБЗОР И ФЛАНГОВЫЕ АТАКИ',hp:150,speed:145,radius:13,range:190,damage:9,reload:.55,vision:520,cost:90,time:5},
 tank:{name:'Танк',role:'ОСНОВНАЯ БРОНЕТЕХНИКА',hp:420,speed:81,radius:21,range:275,damage:38,reload:1.7,vision:340,cost:150,time:8},
 rocket:{name:'Ракетчик',role:'ПРОТИВ ТЯЖЁЛОЙ БРОНИ',hp:210,speed:89,radius:18,range:340,damage:69,reload:3.2,vision:350,cost:180,time:10},
 artillery:{name:'Артиллерия',role:'ДАЛЬНОБОЙНАЯ ПОДДЕРЖКА',hp:180,speed:60,radius:22,range:540,minRange:120,damage:82,reload:4.7,vision:290,cost:240,time:13},
 engineer:{name:'Инженер',role:'ДОБЫЧА МЕТАЛЛА И РЕМОНТ',hp:190,speed:100,radius:17,range:0,damage:0,reload:0,vision:300,cost:100,time:6},
 turret:{name:'Сторожевая башня',role:'ОБОРОНИТЕЛЬНАЯ ПОЗИЦИЯ',hp:550,speed:0,radius:25,range:360,damage:24,reload:1.25,vision:360}
};
const dist=(a,b)=>Math.hypot(a.x-b.x,a.y-b.y);
const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
function makeMap(){
 const blocks=new Uint8Array(COLS*ROWS);
 function patch(x,y,w,h){for(let j=y;j<y+h;j++)for(let i=x;i<x+w;i++)blocks[j*COLS+i]=1;}
 patch(21,13,7,11);patch(23,11,3,3);patch(20,16,2,6);patch(27,17,3,5);patch(8,4,6,3);patch(34,25,5,5);patch(8,27,5,4);patch(37,3,4,2);
 return blocks;
}
function walkable(blocks,x,y,radius=12){
 if(x<radius+4||y<radius+4||x>WIDTH-radius-4||y>HEIGHT-radius-4)return false;
 const r=radius*.78;
 for(const [dx,dy] of [[0,0],[-r,-r],[r,-r],[-r,r],[r,r]])if(blocks[Math.floor((y+dy)/CELL)*COLS+Math.floor((x+dx)/CELL)])return false;
 return true;
}
function lineClear(blocks,a,b,radius=0){
 if(!walkable(blocks,a.x,a.y,radius)||!walkable(blocks,b.x,b.y,radius))return false;
 // Exact segment versus expanded rock cells: sampling can miss a clipped corner.
 const pad=radius*.78+.1,dx=b.x-a.x,dy=b.y-a.y;
 const ix0=clamp(Math.floor((Math.min(a.x,b.x)-pad)/CELL),0,COLS-1),ix1=clamp(Math.floor((Math.max(a.x,b.x)+pad)/CELL),0,COLS-1),iy0=clamp(Math.floor((Math.min(a.y,b.y)-pad)/CELL),0,ROWS-1),iy1=clamp(Math.floor((Math.max(a.y,b.y)+pad)/CELL),0,ROWS-1);
 for(let j=iy0;j<=iy1;j++)for(let i=ix0;i<=ix1;i++){if(!blocks[j*COLS+i])continue;let enter=0,leave=1,hit=true;for(const [p,v,lo,hi]of [[a.x,dx,i*CELL-pad,(i+1)*CELL+pad],[a.y,dy,j*CELL-pad,(j+1)*CELL+pad]]){if(Math.abs(v)<1e-10){if(p<lo||p>hi){hit=false;break;}}else{const t1=(lo-p)/v,t2=(hi-p)/v;enter=Math.max(enter,Math.min(t1,t2));leave=Math.min(leave,Math.max(t1,t2));if(enter>leave){hit=false;break;}}}if(hit)return false;}return true;
}
function findPath(blocks,start,end,radius=14){
 if(!walkable(blocks,end.x,end.y,radius))return null;
 if(lineClear(blocks,start,end,radius))return [{x:end.x,y:end.y}];
 const sx=clamp(Math.floor(start.x/CELL),0,COLS-1),sy=clamp(Math.floor(start.y/CELL),0,ROWS-1),ex=Math.floor(end.x/CELL),ey=Math.floor(end.y/CELL),s=sy*COLS+sx,e=ey*COLS+ex;
 const scores=new Float64Array(COLS*ROWS).fill(Infinity),parent=new Int32Array(COLS*ROWS).fill(-1),closed=new Uint8Array(COLS*ROWS),open=[s];scores[s]=0;
 const h=k=>Math.hypot(k%COLS-ex,Math.floor(k/COLS)-ey);let found=false;
 while(open.length){let bi=0,best=Infinity;for(let i=0;i<open.length;i++){let f=scores[open[i]]+h(open[i]);if(f<best){best=f;bi=i;}}const k=open.splice(bi,1)[0];if(k===e){found=true;break;}if(closed[k])continue;closed[k]=1;const x=k%COLS,y=Math.floor(k/COLS);
  for(const [dx,dy]of [[1,0],[-1,0],[0,1],[0,-1],[1,1],[1,-1],[-1,1],[-1,-1]]){const nx=x+dx,ny=y+dy;if(nx<0||ny<0||nx>=COLS||ny>=ROWS)continue;const nk=ny*COLS+nx;if(closed[nk]||!walkable(blocks,(nx+.5)*CELL,(ny+.5)*CELL,radius))continue;
   if(dx&&dy&&(!walkable(blocks,(x+dx+.5)*CELL,(y+.5)*CELL,radius)||!walkable(blocks,(x+.5)*CELL,(y+dy+.5)*CELL,radius)))continue;
   const ns=scores[k]+(dx&&dy?1.4143:1);if(ns<scores[nk]){scores[nk]=ns;parent[nk]=k;open.push(nk);}
  }
 }
 if(!found)return null;
 const pts=[{x:end.x,y:end.y}];let k=e;
 while(k!==s&&k>=0){pts.push({x:(k%COLS+.5)*CELL,y:(Math.floor(k/COLS)+.5)*CELL});k=parent[k];}
 pts.reverse();const smooth=[];let last=start;
 for(let i=0;i<pts.length;){let j=pts.length-1;while(j>i&&!lineClear(blocks,last,pts[j],radius))j--;smooth.push(pts[j]);last=pts[j];i=j+1;}
 return smooth;
}
class Game{
 constructor(){this.blocks=makeMap();this.units=[];this.resources=[];this.projectiles=[];this.effects=[];this.events=[];this.nextId=1;this.time=0;this.money=[520,650];this.queues=[[],[]];this.started=false;this.paused=false;this.result=null;this.goalHold=0;this.goal={x:2220,y:265,radius:150};this.fog=new Uint8Array(COLS*ROWS);this.visible=new Uint8Array(COLS*ROWS);this.fogTick=0;this.aiTick=0;this.nextRaid=75;this.wave=0;this.eventSeq=0;this.kills=0;this.metalMined=0;this.aiRelocated=false;
  this.base=this.spawn('base',0,345,965);this.base.deployed=1;this.base.mode='deployed';
  this.enemyBase=this.spawn('base',1,2025,1110);this.enemyBase.deployed=1;this.enemyBase.mode='deployed';
  this.spawn('tank',0,510,840);this.spawn('tank',0,550,1010);this.spawn('scout',0,550,690);this.spawn('rocket',0,460,1120);this.spawn('engineer',0,265,1140);
  this.spawn('tank',1,1860,930);this.spawn('tank',1,1940,1250);this.spawn('scout',1,1810,1160);this.spawn('engineer',1,2150,1220);
  this.spawn('turret',1,1730,440);this.spawn('turret',1,2070,370);this.spawn('turret',1,1570,1430);
  for(const [x,y,amount]of [[280,1250,560],[610,1170,350],[700,430,1100],[980,1430,1400],[1560,1180,800],[2160,1330,1500],[1580,610,850]])this.addResource(x,y,amount);
  this.updateFog();
 }
 spawn(type,team,x,y){const t=TYPES[type];const u={id:this.nextId++,type,team,x,y,hp:t.hp,maxHp:t.hp,angle:team?Math.PI:0,turret:team?Math.PI:0,path:[],order:'idle',target:null,cooldown:0,repath:0,moving:false,travel:0,cargo:0,work:0,flash:0,recoil:0};this.units.push(u);return u;}
 addResource(x,y,amount,scrap=false){const r={id:this.nextId++,x,y,amount,max:amount,scrap};this.resources.push(r);return r;}
 event(text,kind='info'){this.events.push({id:++this.eventSeq,time:this.time,text,kind});if(this.events.length>20)this.events.shift();}
 population(team){return this.units.filter(u=>u.hp>0&&u.team===team&&u.type!=='base'&&u.type!=='turret').length;}
 enqueue(type,team=0){const t=TYPES[type],base=team?this.enemyBase:this.base;if(!t||!t.cost||base.hp<=0||this.result)return false;
  if(base.mode!=='deployed'){if(!team)this.event('Сначала разверните завод', 'notice');return false;}
  if(this.money[team]<t.cost){if(!team)this.event('Недостаточно металла', 'notice');return false;}
  if(this.population(team)+this.queues[team].length>=36){if(!team)this.event('Лимит техники: 36 машин','notice');return false;}
  if(this.queues[team].length>=8){if(!team)this.event('Очередь заполнена','notice');return false;}
  this.money[team]-=t.cost;this.queues[team].push({type,remaining:t.time,total:t.time});return true;
 }
 cancel(team=0){const job=this.queues[team].pop();if(job){this.money[team]+=TYPES[job.type].cost;return true;}return false;}
 toggleBase(){const b=this.base;if(b.hp<=0||this.result)return false;if(b.mode==='packing'||b.mode==='deploying')return false;b.path=[];b.order='idle';b.mode=b.mode==='deployed'?'packing':'deploying';this.event(b.mode==='packing'?'Завод складывается. Приготовьте охранение.':'Развёртывание завода: 3 секунды');return true;}
 move(u,x,y,order='move'){if(u.hp<=0||!TYPES[u.type].speed)return false;if(u.type==='base'&&u.mode!=='mobile'){if(!u.team)this.event('Сверните завод: Пробел','notice');return false;}const path=findPath(this.blocks,u,{x,y},TYPES[u.type].radius);if(!path)return false;u.path=path;u.order=order;u.target=null;u.repath=0;return true;}
 command(ids,x,y,targetId=null,attackMove=false){const selected=this.units.filter(u=>ids.includes(u.id)&&!u.team&&u.hp>0);const target=this.units.find(u=>u.id===targetId&&u.team&&this.isVisible(u));const resource=this.resources.find(r=>r.amount>0&&Math.hypot(r.x-x,r.y-y)<55);const repair=this.units.find(u=>u.team===0&&u.hp>0&&u.hp<u.maxHp&&dist(u,{x,y})<TYPES[u.type].radius+20);let issued=0;
  const side=Math.ceil(Math.sqrt(selected.length)),spacing=52;
  selected.forEach((u,i)=>{if(u.type==='engineer'&&resource){u.order='mine';u.target=resource.id;u.mineTarget=resource.id;u.work=0;u.path=[];issued++;return;}if(u.type==='engineer'&&repair&&repair.id!==u.id){u.order='repair';u.target=repair.id;u.path=[];issued++;return;}if(target&&TYPES[u.type].damage){u.order='attack';u.target=target.id;u.path=[];u.repath=0;issued++;return;}
   let dx=selected.length>1?(i%side-(side-1)/2)*spacing:0,dy=selected.length>1?(Math.floor(i/side)-(side-1)/2)*spacing:0;
   if(this.move(u,clamp(x+dx,55,WIDTH-55),clamp(y+dy,55,HEIGHT-55),attackMove?'assault':'move'))issued++;else if(this.move(u,x,y,attackMove?'assault':'move'))issued++;
  });if(!issued&&!target)this.event('Маршрут недоступен','notice');return issued;
 }
 stop(ids){for(const u of this.units)if(!u.team&&ids.includes(u.id)){u.path=[];u.order='hold';u.target=null;u.moving=false;}}
 isVisible(u){return u.team===0||!!this.visible[clamp(Math.floor(u.y/CELL),0,ROWS-1)*COLS+clamp(Math.floor(u.x/CELL),0,COLS-1)];}
 updateFog(){this.visible.fill(0);for(const u of this.units){if(u.team||u.hp<=0)continue;const r=TYPES[u.type].vision,x=Math.floor(u.x/CELL),y=Math.floor(u.y/CELL),n=Math.ceil(r/CELL);for(let j=Math.max(0,y-n);j<=Math.min(ROWS-1,y+n);j++)for(let i=Math.max(0,x-n);i<=Math.min(COLS-1,x+n);i++)if(Math.hypot((i+.5)*CELL-u.x,(j+.5)*CELL-u.y)<r){this.visible[j*COLS+i]=1;this.fog[j*COLS+i]=1;}}}
 advance(u,dt){u.moving=false;if(!u.path.length)return;const p=u.path[0],d=dist(u,p),v=TYPES[u.type].speed*dt;if(d<=v+1){u.x=p.x;u.y=p.y;u.path.shift();}else{const dx=(p.x-u.x)/d,dy=(p.y-u.y)/d;u.x+=dx*v;u.y+=dy*v;u.angle=Math.atan2(dy,dx);u.travel+=v;u.moving=true;}}
 routeNear(u,target,reach=50){if(u.path.length)return;let x=target.x,y=target.y;const d=dist(u,target);if(d>1){x+=(u.x-target.x)/d*reach;y+=(u.y-target.y)/d*reach;}const path=findPath(this.blocks,u,{x,y},TYPES[u.type].radius);if(path)u.path=path;}
 worker(u,dt){const base=u.team?this.enemyBase:this.base;if(base.hp<=0)return;
  if(u.order==='hold'||u.order==='move'){this.advance(u,dt);if(u.order==='move'&&!u.path.length)u.order='idle';return;}
  if(u.order==='repair'){const t=this.units.find(v=>v.id===u.target&&v.hp>0);if(!t||t.hp>=t.maxHp){u.order='idle';u.path=[];return;}if(dist(u,t)<TYPES[t.type].radius+50){u.path=[];u.moving=false;t.hp=Math.min(t.maxHp,t.hp+28*dt);u.work+=dt;}else this.routeNear(u,t,TYPES[t.type].radius+30);this.advance(u,dt);return;}
  if(u.cargo>=40||u.order==='deliver'){
   u.order='deliver';if(dist(u,base)<95){u.path=[];u.moving=false;if(base.mode==='deployed'){this.money[u.team]+=u.cargo;if(!u.team)this.metalMined+=u.cargo;u.cargo=0;u.order='idle';u.target=u.mineTarget||null;}}else{u.repath-=dt;if(u.repath<=0){u.path=[];u.repath=2;}this.routeNear(u,base,65);this.advance(u,dt);}return;
  }
  let r=this.resources.find(r=>r.id===u.target&&r.amount>0);if(!r){const rs=this.resources.filter(r=>r.amount>0&&dist(r,base)<(u.team?600:520));rs.sort((a,b)=>dist(a,u)-dist(b,u));r=rs[0];u.target=r?.id;u.path=[];}
  if(!r){if(u.cargo>0){u.order='deliver';}else u.order='idle';u.moving=false;return;}
  u.order='mine';if(dist(u,r)<60){u.path=[];u.moving=false;u.angle=Math.atan2(r.y-u.y,r.x-u.x);u.work+=dt;const amount=Math.min(r.amount,13*dt,40-u.cargo);u.cargo+=amount;r.amount-=amount;if(r.amount<=0&&u.cargo>0)u.order='deliver';}else{this.routeNear(u,r,38);this.advance(u,dt);}
 }
 acquire(u){let best=null,bd=Infinity;const t=TYPES[u.type];for(const v of this.units){if(v.team===u.team||v.hp<=0||(!u.team&&!this.isVisible(v)))continue;const d=dist(u,v);if(d<t.range+80&&d>=(t.minRange||0)&&d<bd&&lineClear(this.blocks,u,v)){best=v;bd=d;}}return best;}
 fire(u,target){const t=TYPES[u.type];u.cooldown=t.reload;u.flash=.12;u.recoil=1;u.turret=Math.atan2(target.y-u.y,target.x-u.x);this.projectiles.push({x:u.x,y:u.y,fromX:u.x,fromY:u.y,target:target.id,tx:target.x,ty:target.y,team:u.team,speed:u.type==='rocket'?390:u.type==='artillery'?470:760,damage:t.damage,type:u.type,age:0});}
 damage(u,amount){if(u.hp<=0)return;u.hp-=amount;u.hit=.15;if(u.hp<=0){u.hp=0;u.path=[];this.effects.push({kind:'explosion',x:u.x,y:u.y,size:u.type==='base'?100:32,age:0,life:1.7});if(u.type!=='base'){this.addResource(u.x,u.y,u.type==='turret'?50:Math.floor((TYPES[u.type].cost||90)*.3),true);}if(u.team)this.kills++;if(u.type==='base')this.event(u.team?'Вражеский завод уничтожен. Путь к перевалу открыт.':'Командный завод потерян','combat');}}
 combat(u,dt){const t=TYPES[u.type];if(!t.damage)return;let target=this.units.find(v=>v.id===u.target&&v.hp>0&&v.team!==u.team);const explicit=u.order==='attack';if(target&&!u.team&&!this.isVisible(target)){if(explicit){this.move(u,target.x,target.y,'assault');}target=null;u.target=null;}
  if(!explicit&&target&&(dist(u,target)>t.range+80||dist(u,target)<(t.minRange||0)))target=null;
  if(!explicit&&(u.order==='move'||(u.type==='base'&&u.mode!=='deployed')))target=null;
  else if(!target){target=this.acquire(u);if(target&&!explicit)u.target=target.id;}
  if(!target){if(explicit){u.order='idle';u.target=null;u.path=[];}return;}
  const d=dist(u,target),clear=lineClear(this.blocks,u,target);u.turret=Math.atan2(target.y-u.y,target.x-u.x);
  if(d<=t.range&&d>=(t.minRange||0)&&clear){if(explicit||u.order==='assault')u.moving=false;if(u.cooldown<=0)this.fire(u,target);}
  else if(explicit&&t.speed&&u.type!=='base'){u.repath-=dt;if(u.repath<=0){u.path=[];u.repath=.8;let distance=d<(t.minRange||0)?-(t.minRange+80):t.range*.8;const nx=target.x+(u.x-target.x)/Math.max(d,1)*distance,ny=target.y+(u.y-target.y)/Math.max(d,1)*distance;u.path=findPath(this.blocks,u,{x:clamp(nx,30,WIDTH-30),y:clamp(ny,30,HEIGHT-30)},t.radius)||[];}this.advance(u,dt);}
 }
 updateAI(dt){this.aiTick-=dt;if(this.aiTick>0)return;this.aiTick=3;if(this.enemyBase.hp<=0)return;
  if(this.queues[1].length<2){let type=this.population(1)<5?'tank':['scout','tank','rocket','tank','artillery'][Math.floor(this.time/7)%5];if(!this.units.some(u=>u.team&&u.type==='engineer'&&u.hp>0))type='engineer';this.enqueue(type,1);}
  if(this.time>this.nextRaid){this.wave++;this.nextRaid=this.time+65;const troops=this.units.filter(u=>u.team&&u.hp>0&&!['base','engineer','turret'].includes(u.type));for(const u of troops){u.order='attack';u.target=this.base.id;u.path=[];u.repath=0;}this.event('Разведка: вражеская группа выдвинулась к заводу','combat');}
  if(!this.aiRelocated&&this.money[1]<150&&!this.resources.some(r=>r.amount>30&&dist(r,this.enemyBase)<600)){
   const b=this.enemyBase;if(b.mode==='deployed'){b.mode='packing';this.aiRelocated=true;this.event('Противник сворачивает производство и меняет позицию');}
  }
 }
 update(dt){if(!this.started||this.paused||this.result)return;dt=Math.min(dt,.1);this.time+=dt;this.fogTick-=dt;if(this.fogTick<=0){this.updateFog();this.fogTick=.2;}this.updateAI(dt);
  for(let team=0;team<2;team++){const b=team?this.enemyBase:this.base;const job=this.queues[team][0];if(job&&b.hp>0&&b.mode==='deployed'){job.remaining-=dt;if(job.remaining<=0){let p=null;for(let i=0;i<24;i++){const a=i*2.4,r=105+Math.floor(i/8)*45,x=b.x+Math.cos(a)*r,y=b.y+Math.sin(a)*r;if(walkable(this.blocks,x,y,TYPES[job.type].radius)){p={x,y};break;}}if(p){const u=this.spawn(job.type,team,p.x,p.y);this.queues[team].shift();if(!team)this.event(TYPES[job.type].name+': машина готова');else if(this.time>75&&u.type!=='engineer'){u.order='attack';u.target=this.base.id;}}}}
  }
  for(const u of this.units){if(u.hp<=0)continue;u.cooldown-=dt;u.flash=Math.max(0,u.flash-dt);u.hit=Math.max(0,(u.hit||0)-dt);u.recoil=Math.max(0,u.recoil-dt*4);u.moving=false;
   if(u.type==='base'){if(u.mode==='packing'){u.deployed=Math.max(0,u.deployed-dt/3);if(u.deployed===0){u.mode='mobile';if(u.team&&this.aiRelocated)this.move(u,1550,1150);}}else if(u.mode==='deploying'){u.deployed=Math.min(1,u.deployed+dt/3);if(u.deployed===1)u.mode='deployed';}if(u.mode==='mobile'){this.advance(u,dt);if(u.team&&this.aiRelocated&&!u.path.length){u.mode='deploying';}}}
   else if(u.type==='engineer'){this.worker(u,dt);continue;}
   else if(u.order!=='attack'){let firing=false;if(u.order==='assault'){const v=this.acquire(u);firing=v&&dist(u,v)<=TYPES[u.type].range&&dist(u,v)>=(TYPES[u.type].minRange||0);}if(!firing)this.advance(u,dt);if(!u.path.length&&(u.order==='move'||u.order==='assault')){u.order='idle';u.target=null;}}
   this.combat(u,dt);
  }
  // Gentle separation preserves path clearance and prevents units stacking at a destination.
  const live=this.units.filter(u=>u.hp>0);for(let i=0;i<live.length;i++)for(let j=i+1;j<live.length;j++){const a=live[i],b=live[j];if(a.type==='turret'&&b.type==='turret')continue;const d=dist(a,b),min=(TYPES[a.type].radius+TYPES[b.type].radius)*.8;if(d<min&&d>.01){const push=(min-d)*.18,dx=(a.x-b.x)/d*push,dy=(a.y-b.y)/d*push;for(const [u,s]of [[a,1],[b,-1]])if(TYPES[u.type].speed&&u.type!=='base'&&walkable(this.blocks,u.x+dx*s,u.y+dy*s,TYPES[u.type].radius)){u.x+=dx*s;u.y+=dy*s;}}}
  for(const p of this.projectiles){p.age+=dt;const target=this.units.find(u=>u.id===p.target&&u.hp>0);if(target){p.tx=target.x;p.ty=target.y;}const d=Math.hypot(p.tx-p.x,p.ty-p.y);if(d<p.speed*dt){p.dead=true;this.effects.push({kind:'impact',x:p.tx,y:p.ty,size:p.type==='artillery'?43:20,age:0,life:.65});if(target){this.damage(target,p.damage);if(p.type==='artillery')for(const u of live)if(u.id!==target.id&&u.team!==p.team&&dist(u,target)<85)this.damage(u,p.damage*.35);}}else{p.x+=(p.tx-p.x)/d*p.speed*dt;p.y+=(p.ty-p.y)/d*p.speed*dt;}}
  this.projectiles=this.projectiles.filter(p=>!p.dead&&p.age<8);for(const e of this.effects)e.age+=dt;this.effects=this.effects.filter(e=>e.age<e.life);
  if(this.base.hp<=0){this.result='defeat';return;}
  const atGoal=dist(this.base,this.goal)<this.goal.radius,blocked=this.units.some(u=>u.team&&u.hp>0&&dist(u,this.goal)<300);this.goalHold=atGoal&&!blocked?this.goalHold+dt:Math.max(0,this.goalHold-dt*2);if(this.goalHold>=8)this.result='victory';
 }
}
const API={Game,TYPES,CELL,COLS,ROWS,WIDTH,HEIGHT,dist,clamp,walkable,lineClear,findPath,makeMap};if(typeof module!=='undefined')module.exports=API;root.Iron=API;
})(typeof globalThis!=='undefined'?globalThis:this);
