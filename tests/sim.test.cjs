const test=require('node:test');
const assert=require('node:assert/strict');
const {Game,TYPES,findPath,walkable,lineClear,dist}=require('../src/sim.js');
function tick(g,seconds){for(let i=0;i<Math.round(seconds/.05);i++)g.update(.05);}
function game(){const g=new Game();g.started=true;return g;}

test('crawler path crosses either pass without intersecting the ridge',()=>{
 const g=game(),end={x:2220,y:265},path=findPath(g.blocks,g.base,end,TYPES.base.radius);assert.ok(path&&path.length>1);let p=g.base;for(const next of path){assert.ok(lineClear(g.blocks,p,next,TYPES.base.radius));p=next;}assert.equal(findPath(g.blocks,g.base,{x:1200,y:900},47),null);
});
test('production charges up front, pauses when packed and resumes after deploying',()=>{
 const g=game();g.units=g.units.filter(u=>!u.team);assert.equal(g.enqueue('tank'),true);assert.equal(g.money[0],370);tick(g,2);const remaining=g.queues[0][0].remaining;g.toggleBase();tick(g,4);assert.equal(g.base.mode,'mobile');assert.ok(Math.abs(g.queues[0][0].remaining-remaining)<.001);g.toggleBase();tick(g,10);assert.equal(g.queues[0].length,0);assert.equal(g.population(0),6);
});
test('cancel refunds the most recent queue item; invalid types cannot be built',()=>{
 const g=game();assert.equal(g.enqueue('bogus'),false);g.enqueue('scout');g.enqueue('tank');g.cancel();assert.equal(g.money[0],430);assert.equal(g.queues[0][0].type,'scout');g.cancel();assert.equal(g.money[0],520);
});
test('engineer mines finite resources and delivers cargo',()=>{
 const g=game();g.units=g.units.filter(u=>!u.team);const stock=g.resources.reduce((n,r)=>n+r.amount,0);tick(g,40);assert.ok(g.money[0]>520);assert.ok(g.metalMined>=40);assert.ok(g.resources.reduce((n,r)=>n+r.amount,0)<stock);
});
test('engineer repairs a selected damaged friendly unit',()=>{
 const g=game(),worker=g.units.find(u=>u.type==='engineer'&&!u.team),tank=g.units.find(u=>u.type==='tank'&&!u.team);tank.hp=100;worker.x=tank.x-50;worker.y=tank.y;g.command([worker.id],tank.x,tank.y);assert.equal(worker.order,'repair');tick(g,3);assert.ok(tank.hp>170);
});
test('movement orders finish and never enter blocked terrain',()=>{
 const g=game();g.units=g.units.filter(u=>!u.team);g.toggleBase();tick(g,3.2);assert.ok(g.move(g.base,1600,1450));for(let i=0;i<1300;i++){g.update(.05);assert.ok(walkable(g.blocks,g.base.x,g.base.y,TYPES.base.radius));}assert.ok(dist(g.base,{x:1600,y:1450})<2);
});
test('pause freezes timers, cargo and build queue',()=>{
 const g=game();g.enqueue('tank');g.paused=true;tick(g,20);assert.equal(g.time,0);assert.equal(g.queues[0][0].remaining,8);assert.equal(g.money[0],370);
});
test('attack order deals damage, creates salvage and survives target death',()=>{
 const g=game();g.units=g.units.filter(u=>u.type==='base');const a=g.spawn('tank',0,500,600),b=g.spawn('scout',1,680,600);b.hp=20;g.updateFog();g.command([a.id],b.x,b.y,b.id);tick(g,3);assert.equal(b.hp,0);assert.ok(g.resources.some(r=>r.scrap));assert.equal(g.kills,1);assert.equal(a.order,'idle');
});
test('enemy spends resources and launches real units in a raid',()=>{
 const g=game();g.base.hp=999999;tick(g,80);assert.ok(g.wave>=1);assert.ok(g.units.some(u=>u.team&&u.order==='attack'));assert.ok(g.money[1]>=0);assert.ok(g.units.filter(u=>u.team).length>8);
});
test('goal requires a surviving crawler and a clear zone',()=>{
 const g=game();g.base.x=g.goal.x;g.base.y=g.goal.y;g.spawn('tank',1,g.goal.x+50,g.goal.y);tick(g,9);assert.equal(g.result,null);g.units=g.units.filter(u=>!u.team);tick(g,8.2);assert.equal(g.result,'victory');const loss=game();loss.damage(loss.base,99999);tick(loss,.1);assert.equal(loss.result,'defeat');
});
test('fog conceals enemy units and remembers explored terrain',()=>{
 const g=game();assert.equal(g.isVisible(g.enemyBase),false);g.base.x=g.enemyBase.x-80;g.base.y=g.enemyBase.y;g.updateFog();assert.equal(g.isVisible(g.enemyBase),true);const k=Math.floor(g.enemyBase.y/50)*48+Math.floor(g.enemyBase.x/50);g.base.x=345;g.base.y=965;g.updateFog();assert.equal(g.visible[k],0);assert.equal(g.fog[k],1);
});
