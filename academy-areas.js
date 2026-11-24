/* Compact Academy Grounds and separate Artifact Chamber for the Pages build. */
(()=>{'use strict';
const runtime=window.KeseralRuntime,updates=window.KeseralAcademyUpdates;
if(!runtime||!updates)return;
let area='academy';
const originalInteract=updates.interact.bind(updates);
const originalDrawTargets=updates.drawTargets.bind(updates);
const originalUpdateMap=updates.updateMap.bind(updates);
const unlocked=()=>{const s=updates.state?.signal_beneath_stones;return !!s&&(s.stage>=4||s.done)};
const inChamber=()=>area==='chamber';
updates.interact=(x,y)=>{
	if(area==='academy'&&Math.abs(x-5705)<=100){
		if(!unlocked()){runtime.toast('The ancient mechanism has not opened this entrance.');return true}
		runtime.setArea('chamber',130,520);
		return true;
	}
	if(inChamber()&&Math.abs(x-120)<=100){runtime.setArea('academy',5600,520);return true}
	return originalInteract(inChamber()?x+5670:x,y);
};
updates.drawTargets=(ctx,cam,x,y)=>{if(inChamber())return originalDrawTargets(ctx,cam+5670,x+5670,y);return originalDrawTargets(ctx,cam,x,y)};
updates.updateMap=x=>{if(!inChamber())return originalUpdateMap(x);const marker=document.querySelector('.academy-map-you');if(marker)marker.setAttribute('cx','752');};
function drawGrounds(ctx,cam,p,floorY){
	if(inChamber())return;
	const x=5705-cam,open=unlocked();
	ctx.fillStyle='#211827';ctx.fillRect(x-48,floorY-172,96,164);ctx.strokeStyle='#b9905c';ctx.lineWidth=8;ctx.beginPath();ctx.moveTo(x-55,floorY-8);ctx.lineTo(x-55,floorY-164);ctx.quadraticCurveTo(x,floorY-235,x+55,floorY-164);ctx.lineTo(x+55,floorY-8);ctx.stroke();
	if(open){ctx.fillStyle='rgba(135,76,203,.24)';ctx.fillRect(x-36,floorY-154,72,144);ctx.shadowColor='#c185ff';ctx.shadowBlur=24;ctx.strokeStyle='#b377e9';ctx.lineWidth=3;ctx.beginPath();ctx.arc(x,floorY-95,29,0,Math.PI*2);ctx.stroke();ctx.shadowBlur=0}
	else{ctx.strokeStyle='#bb8c56';ctx.lineWidth=5;for(let i=-2;i<=2;i++){ctx.beginPath();ctx.moveTo(x+i*16,floorY-150);ctx.lineTo(x+i*16,floorY-7);ctx.stroke()}ctx.fillStyle='#dbb56d';ctx.fillRect(x-48,floorY-104,96,8)}
	if(Math.abs(p.x-5705)<100){ctx.fillStyle='#f1d9a9';ctx.font='11px monospace';ctx.textAlign='center';ctx.fillText(open?'F  DESCEND TO ARTIFACT CHAMBER':'THREE CLUES REVEAL THE WAY',x,floorY-250)}
}
function draw(ctx,cam,p,floorY){
	if(!inChamber())return false;
	const w=1280,h=720;
	const sky=ctx.createLinearGradient(0,0,0,h);sky.addColorStop(0,'#151122');sky.addColorStop(.72,'#281d34');sky.addColorStop(1,'#3b2b3b');ctx.fillStyle=sky;ctx.fillRect(0,0,w,h);
	// Ancient carved chamber walls, brass ribs, and restrained arcane illumination.
	for(let i=0;i<8;i++){
		const x=i*330-cam+110,top=105+(i%3)*18;
		ctx.fillStyle='#211a2b';ctx.fillRect(x-64,top,128,floorY-top-18);
		ctx.strokeStyle='#795c54';ctx.lineWidth=11;ctx.beginPath();ctx.moveTo(x-72,floorY-12);ctx.lineTo(x-72,top+45);ctx.quadraticCurveTo(x,top-60,x+72,top+45);ctx.lineTo(x+72,floorY-12);ctx.stroke();
		ctx.strokeStyle='#bd8c55';ctx.lineWidth=2;ctx.beginPath();ctx.moveTo(x-67,floorY-15);ctx.lineTo(x-67,top+45);ctx.quadraticCurveTo(x,top-48,x+67,top+45);ctx.lineTo(x+67,floorY-15);ctx.stroke();
		for(let row=0;row<4;row++){ctx.fillStyle=i%2?'#302437':'#382a3b';ctx.fillRect(x-49,top+56+row*67,96,48);ctx.strokeStyle='#513e48';ctx.lineWidth=1;ctx.strokeRect(x-49,top+56+row*67,96,48)}
		ctx.strokeStyle='#a77f57';ctx.lineWidth=3;ctx.beginPath();ctx.moveTo(x-18,top+86);ctx.lineTo(x-5,top+119);ctx.lineTo(x+9,top+86);ctx.stroke();
	}
	// The separated entrance arch stands at the left edge and remains the return path.
	let doorX=120-cam;ctx.fillStyle='#15101f';ctx.fillRect(doorX-46,floorY-173,92,164);ctx.strokeStyle='#c0935e';ctx.lineWidth=8;ctx.beginPath();ctx.moveTo(doorX-54,floorY-8);ctx.lineTo(doorX-54,floorY-166);ctx.quadraticCurveTo(doorX,floorY-245,doorX+54,floorY-166);ctx.lineTo(doorX+54,floorY-8);ctx.stroke();ctx.strokeStyle='#6d4b48';ctx.lineWidth=3;ctx.strokeRect(doorX-35,floorY-148,70,140);
	// Central dormant device and old House-neutral markings.
	const dx=1320-cam,dy=floorY-8,pulse=.5+.5*Math.sin(performance.now()*.002);
	ctx.fillStyle='#211a27';ctx.fillRect(dx-160,dy-46,320,42);ctx.fillStyle='#a77a4c';ctx.fillRect(dx-178,dy-54,356,10);
	ctx.fillStyle='#241c2b';ctx.fillRect(dx-104,dy-168,208,116);ctx.strokeStyle='#b48a55';ctx.lineWidth=6;ctx.beginPath();ctx.arc(dx,dy-208,98,0,Math.PI*2);ctx.stroke();ctx.strokeStyle='#8b66a9';ctx.lineWidth=3;ctx.beginPath();ctx.arc(dx,dy-208,69,0,Math.PI*2);ctx.stroke();
	ctx.shadowColor='#a66af1';ctx.shadowBlur=24+10*pulse;ctx.fillStyle=`rgba(173,108,239,${.48+.35*pulse})`;ctx.beginPath();ctx.moveTo(dx,dy-244);ctx.lineTo(dx+26,dy-208);ctx.lineTo(dx,dy-174);ctx.lineTo(dx-26,dy-208);ctx.closePath();ctx.fill();ctx.shadowBlur=0;
	for(let i=0;i<8;i++){const a=i*Math.PI/4;ctx.strokeStyle='#d2a368';ctx.lineWidth=3;ctx.beginPath();ctx.moveTo(dx+Math.cos(a)*75,dy-208+Math.sin(a)*75);ctx.lineTo(dx+Math.cos(a)*104,dy-208+Math.sin(a)*104);ctx.stroke()}
	for(let i=0;i<3;i++){ctx.strokeStyle='rgba(190,142,222,.8)';ctx.lineWidth=3;ctx.beginPath();ctx.moveTo(dx-43+i*43,dy-104);ctx.lineTo(dx-21+i*21,dy-151);ctx.stroke()}
	const awake=document.body.classList.contains('academy-awakened');
	if(awake){ctx.fillStyle='rgba(135,69,195,.17)';ctx.fillRect(0,floorY-142,w,142);ctx.shadowColor='#bc7cff';ctx.shadowBlur=30;ctx.strokeStyle=`rgba(203,145,255,${.28+.35*pulse})`;ctx.lineWidth=4;ctx.beginPath();ctx.arc(dx,dy-208,134,0,Math.PI*2);ctx.stroke();ctx.shadowBlur=0}
	// Floor is a broad uninterrupted walk surface with a gold-cut coping edge.
	ctx.fillStyle='#302631';ctx.fillRect(0,floorY-12,w,h-floorY+12);ctx.fillStyle='#b58b5b';ctx.fillRect(0,floorY-16,w,5);ctx.fillStyle='#604c4d';ctx.fillRect(0,floorY-10,w,12);for(let x=0;x<w;x+=54){ctx.fillStyle=(x/54|0)%2?'#524249':'#5d4a4d';ctx.fillRect(x+2,floorY-7,50,8);ctx.fillStyle='#887060';ctx.fillRect(x+8,floorY-6,34,2)}
	if(Math.abs(p.x-120)<105){ctx.fillStyle='#f4d8a2';ctx.font='12px monospace';ctx.textAlign='center';ctx.fillText('F  RETURN TO ACADEMY GROUNDS',doorX,floorY-210)}
	if(Math.abs(p.x-1320)<150&&!awake){ctx.fillStyle='#e5d5f4';ctx.font='11px monospace';ctx.textAlign='center';ctx.fillText('F  INSPECT THE DORMANT DEVICE',dx,dy-280)}
	if(Math.abs(p.x-1440)<150&&awake){ctx.fillStyle='#f0dcff';ctx.font='11px monospace';ctx.textAlign='center';ctx.fillText('F  THE DEVICE ANSWERS',1440-cam,floorY-285)}
	ctx.fillStyle='#c6a979';ctx.font='10px Georgia';ctx.textAlign='center';ctx.fillText('THE CHAMBER BENEATH INGENIARII',w/2,54);
	return true;
}
runtime.setArea=(next,x,y)=>{area=next==='chamber'?'chamber':'academy';runtime._setPosition(x,y);runtime._hideEnemies(inChamber());runtime._setCameraWidth(inChamber()?2400:5860);};
runtime.areaWidth=()=>inChamber()?2400:5860;
runtime.playLimit=()=>inChamber()?2400:(unlocked()?5860:5710);
window.KeseralAreas={draw,drawGrounds,isChamber:inChamber,width:()=>inChamber()?2400:5860};
})();
