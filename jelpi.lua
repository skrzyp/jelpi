-- the adventures of jelpi
-- by zep

-- to do:
-- levels and monsters
-- title / restart logic
-- block loot
-- top-solid ground
-- better duping

-- config: num_players 1 or 2
num_players = 1
corrupt_mode = false
max_actors = 128

music(0, 0, 3)


function make_actor(k,x,y,d)
	local a = {}
	a.kind = k
	a.life = 1
	a.x=x a.y=y a.dx=0 a.dy=0
	a.ddy = 0.06 -- gravity
 a.w=0.3 a.h=0.5 -- half-width
 a.d=d a.bounce=0.8
 a.frame = 1  a.f0 = 0
 a.t=0
 a.standing = false
 if (count(actor) < max_actors) then
  add(actor, a)
 end
	return a
end

function make_sparkle(x,y,frame,col)
 local s = {}
 s.x=x
 s.y=y
 s.frame=frame
 s.col=col
 s.t=0 s.max_t = 8+rnd(4)
 s.dx = 0 s.dy = 0
 s.ddy = 0
 add(sparkle,s)
 return s
end

function make_player(x, y, d)
 pl = make_actor(1, x, y, d)
 pl.charge = 0
 pl.super  = 0
 pl.score  = 0
 pl.bounce = 0
 pl.delay  = 0
 pl.id     = 0 -- player 1
 pl.pal    = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15}
 
 return pl
end

-- called at start by pico-8
function _init()

 actor = {}
 sparkle = {}
 
 -- spawn player
 for y=0,63 do for x=0,127 do
  if (mget(x,y) == 48) then
   player = make_player(x,y+1,1)

   if (num_players==2) then
    player2 = make_player(x+2,y+1,1)
    player2.id = 1
    player2.pal = {1,3,3,4,5,6,7,11,9,10,11,12,13,15,7} 
   end
   
  end
 end end
 t = 0
 
 death_t = 0
end

-- clear_cel using neighbour val
-- prefer empty, then non-ground
-- then left neighbour
function clear_cel(x, y)
 val0 = mget(x-1,y)
 val1 = mget(x+1,y)
 if (val0 == 0 or val1 == 0) then
  mset(x,y,0)
 elseif (not fget(val1,1)) then
  mset(x,y,val1)
 else
  mset(x,y,val0)
 end
end


function move_spawns(x0, y0)

 -- spawn stuff close to x0,y0

 for y=0,32 do
  for x=x0-10,x0+10 do
   val = mget(x,y)
   m = nil

   -- pickup
   if (fget(val, 5)) then    
    m = make_actor(2,x+0.5,y+1,1)
    m.f0 = val
    m.frame = val
    if (fget(val,4)) then
     m.ddy = 0 -- zero gravity
    end
   end

   -- monster
   if (fget(val, 3)) then
    m = make_actor(3,x+0.5,y+1,-1)
    m.f0=val
    m.frame=val
   end
   
   -- clear cel if spawned something
   if (m ~= nil) then
    clear_cel(x,y)
   end
  end
 end

end

-- test if a point is solid
function solid (x, y)
	if (x < 0 or x >= 128 ) then
		return true end
				
	val = mget(x, y)
	return fget(val, 1)
end

function move_pickup(a)
 a.frame = a.f0
-- if (flr((t/4) % 2) == 0) then
--  a.frame = a.f0+1
-- end
end

function move_player(pl)

 local b = pl.id

 if (pl.life == 0) then
    death_t = 1
    for i=1,32 do
     s=make_sparkle(
      pl.x, pl.y-0.6, 96, 0)
     s.dx = cos(i/32)/2
     s.dy = sin(i/32)/2
     s.max_t = 30 
     s.ddy = 0.01
     s.frame=96+rnd(3)
     s.col = 7
    end
    
    del(actor,pl)
    
    sfx(16)
    music(-1)
    sfx(5)

  return
 end


 accel = 0.05
 if (pl.charge > 10) then
  accel = 0.08
 end
 
 if (not pl.standing) then
  accel = accel / 2
 end
  
 -- player control
	if (btn(0,b)) then 
			pl.dx = pl.dx - accel; pl.d=-1 end
	if (btn(1,b)) then 
		pl.dx = pl.dx + accel; pl.d=1 end

	if ((btn(4,b) or btn(2,b)) and 
--		solid(pl.x,pl.y)) then 
  pl.standing) then
		pl.dy = -0.7
  sfx(8)
 end

 -- charge

 if (btn(5,b) and pl.charge == 0
 and pl.delay == 0) then
  pl.charge = 15
  
  pl.dx = pl.dx + pl.d * 0.4
  
  if (not pl.standing) then
   pl.dy = pl.dy - 0.2
  end 
 
  sfx(11)
 
 end
 
 -- charging
 
	if (pl.charge > 0 or
	    pl.super  > 0) then
	 pl.frame = 53
	 
	 if (abs(pl.dx) > 0.4 or
	     abs(pl.dy) > 0.2
	 ) then
	 
	 for i=1,3 do
	  local s = make_sparkle(
	   pl.x+pl.dx*i/3, 
	   pl.y+pl.dy*i/3 - 0.3,
	   96+rnd(3), (pl.t*3+i)%9+7)
	  if (rnd(2) < 1) then
	   s.col = 7
	  end
	  s.dx = -pl.dx*0.1
	  s.dy = -0.05*i/4
	  s.x = s.x + rnd(0.6)-0.3
	  s.y = s.y + rnd(0.6)-0.3
  end
  end
	end 
	
	pl.charge = max(0, pl.charge-1)
 if (pl.charge > 0) then
  pl.delay = 10
 else
  pl.delay = max(0,pl.delay-1)
 end

 pl.super = max(0, pl.super-1)
 
 -- frame	

 if (pl.standing) then
	 pl.f0 = (pl.f0+abs(pl.dx)*2+4) % 4
 else
	 pl.f0 = (pl.f0+abs(pl.dx)/2+4) % 4 
 end
 
 if (abs(pl.dx) < 0.1) 
 then
  pl.frame=48 pl.f0=0
 else
	 pl.frame = 49+flr(pl.f0)
	end

 if (pl == player2) then
  pl.frame = pl.frame +75-48
 end
	
end

function move_monster(m)
 m.dx = m.dx + m.d * 0.02

	m.f0 = (m.f0+abs(m.dx)*3+4) % 4
 m.frame = 112 + flr(m.f0)

 if (false and m.standing and rnd(100) < 1)
 then
  m.dy = -1
 end

end

function move_actor(pl)

 -- to do: replace with callbacks

 if (pl.kind == 1) then
  move_player(pl)
 end
 
 if (pl.kind == 2) then
  move_pickup(pl)
 end

 if (pl.kind == 3) then
  move_monster(pl)
 end

 pl.standing=false
 
 -- x movement 
	
 x1 = pl.x + pl.dx +
      sgn(pl.dx) * 0.3
      
 local broke_block = false

 if(not solid(x1,pl.y-0.5)) then
		pl.x = pl.x + pl.dx  
	else -- hit wall
		
	 -- search for contact point
	 while (not solid(pl.x + sgn(pl.dx)*0.3, pl.y-0.5)) do
	  pl.x = pl.x + sgn(pl.dx) * 0.1
	 end

  -- if charging, break block	
	 if (pl.charge ~= nil) then
	 
   if (pl.charge > 0 or 
       pl.super  > 0) then
    val = mget(x1, pl.y-0.5,0)
    if (fget(val,4)) then
     clear_cel(x1,pl.y-0.5)
     sfx(10)
     broke_block = true
     
     -- make debris
     
     for by=0,1 do
      for bx=0,1 do
       s=make_sparkle(
       0.25+flr(x1) + bx*0.5, 
       0.25+flr(pl.y-0.5) + by*0.5,
       22, 0)
       s.dx = (bx-0.5)/4
       s.dy = (by-0.5)/4
       s.max_t = 30 
       s.ddy = 0.02
      end
     end
     
    else
     if (abs(pl.dx) > 0.2) then
      sfx(12) -- thump
     end
    end
    
    -- bumping kills charge
    if (pl.charge < 20) then
     pl.charge = 0
    end
    
   end
	 end

  -- bounce	
  if (pl.super == 0 or 
      not broke_block) then
   pl.dx = pl.dx * -0.5
  end

  if (pl.kind == 3) then
   pl.d = pl.d * -1
   pl.dx=0
  end

	end
	
 -- y movement

 if (pl.dy < 0) then
  -- going up
  
  if (solid(pl.x-0.2, pl.y+pl.dy-1) or
   solid(pl.x+0.2, pl.y+pl.dy-1))
  then
   pl.dy=0
   
   -- search up for collision point
   while ( not (
   solid(pl.x-0.2, pl.y-1) or
   solid(pl.x+0.2, pl.y-1)))
   do
    pl.y = pl.y - 0.01
   end

  else
   pl.y = pl.y + pl.dy
  end

	else

  -- going down
  if (solid(pl.x-0.2, pl.y+pl.dy) or
   solid(pl.x+0.2, pl.y+pl.dy)) then

	  -- bounce
   if (pl.bounce > 0 and 
       pl.dy > 0.2) 
   then
    pl.dy = pl.dy * -pl.bounce
   else
 
    pl.standing=true
    pl.dy = 0
    
   end

   --snap down
   while (not (
     solid(pl.x-0.2,pl.y) or
     solid(pl.x+0.2,pl.y)
     ))
    do pl.y = pl.y + 0.05 end
  
   --pop up even if bouncing
   while(solid(pl.x-0.2,pl.y-0.1)) do
    pl.y = pl.y - 0.05 end
   while(solid(pl.x+0.2,pl.y-0.1)) do
    pl.y = pl.y - 0.05 end
    
  else
   pl.y = pl.y + pl.dy  
  end

 end


 -- gravity and friction
	pl.dy = pl.dy + pl.ddy
 pl.dy = pl.dy * 0.95

 -- x friction
 if (pl.standing) then
 	pl.dx = pl.dx * 0.8
	else
 	pl.dx = pl.dx * 0.9
	end

 -- counters
 pl.t = pl.t + 1
end

function collide_event(a1, a2)
 if(a1.kind==1) then
  if(a2.kind==2) then

   if (a2.frame==64) then
    a1.super = 120
    a1.dx = a1.dx * 2
    --a1.dy = a1.dy-0.1
   -- a1.standing = false
    sfx(13)
   end

   -- gem
   if (a2.frame==80) then
    a1.score = a1.score + 1
    sfx(9)
   end

   del(actor,a2)

  end
  
  -- charge or dupe monster
  
  if(a2.kind==3) then -- monster
   if(a1.charge > 0 or 
      a1.super  > 0 or
     (a1.y-a1.dy) < a2.y-0.7) then
    -- slow down player
    a1.dx = a1.dx * 0.7
    a1.dy = a1.dy * -0.7-- - 0.2
    
    -- explode
    for i=1,16 do
     s=make_sparkle(
      a2.x, a2.y-0.5, 96+rnd(3), 7)
     s.dx = s.dx + rnd(0.4)-0.2
     s.dy = s.dy + rnd(0.4)-0.2
     s.max_t = 30 
     s.ddy = 0.01
     
    end
    
    -- kill monster
    -- to do: in move_monster
    sfx(14)
    del(actor,a2)
    
   else

    -- player death
    a1.life=0


   end
  end
   
 end
end

function move_sparkle(sp)
 if (sp.t > sp.max_t) then
  del(sparkle,sp)
 end
 
 sp.x = sp.x + sp.dx
 sp.y = sp.y + sp.dy
 sp.dy= sp.dy+ sp.ddy
 sp.t = sp.t + 1
end


function collide(a1, a2)
 if (a1==a2) then return end
 local dx = a1.x - a2.x
 local dy = a1.y - a2.y
 if (abs(dx) < a1.w+a2.w) then
  if (abs(dy) < a1.h+a2.h) then
   collide_event(a1, a2)
  end
 end
end

function collisions()

 for a1 in all(actor) do
  collide(player,a1)
 end

 if (player2 ~= nil) then
  for a1 in all(actor) do
   collide(player2,a1)
  end
 end

end

function outgame_logic()

 if (death_t > 0) then
  death_t = death_t + 1
  if (death_t > 30 and 
   btn(4) or btn(5))
  then 
    music(-1)
    sfx(-1)
    sfx(0)
    dpal={0,1,1, 2,1,13,6,
          4,4,9,3, 13,1,13,14}
          
    -- palette fade
    for i=0,40 do
     for j=1,15 do
      col = j
      for k=1,((i+(j%5))/4) do
       col=dpal[col]
      end
      pal(j,col,1)
     end
     flip()
    end
    
    -- restart cart end of slice
    run()
   end
 end
end

function _update()

	foreach(actor, move_actor)		
	foreach(sparkle, move_sparkle)
 collisions()
 move_spawns(player.x, player.y)

 outgame_logic()
 
 if (corrupt_mode) then
  for i=1,5 do
   poke(rnd(0x8000),rnd(0x100))
  end
 end
 
	t=t+1
end

function draw_sparkle(s)
 
 if (s.col > 0) then
  for i=1,15 do
   pal(i,s.col)
  end
 end

 spr(s.frame, s.x*8-4, s.y*8-4)

 pal()
end

function draw_actor(pl)

 if (pl.pal ~= nil) then
  for i=1,15 do
--   pal(i, pl.pal[i])
  end
 end

 if (pl.charge ~= nil and 
     pl.charge > 0) then
 
  for i=2,15 do
   pal(i,7+((pl.t/2) % 8))
  end
--  pal(2,7)

 end

 if (pl.super ~= nil and 
     pl.super > 0) then
 
  for i=2,15 do
   pal(i,6+((pl.t/2) % 2))
  end

 end

	spr(pl.frame, 
  pl.x*8-4, pl.y*8-8, 
  1, 1, pl.d < 0)
  
 pal()
end

function _draw()

 -- sky
	camera (0, 0)
	rectfill (0,0,127,127,12) 
 --for y=1,7 do
 -- rect(0,63-y*2.5,127,63-y*2.5,6) end

 -- background
 
-- sspr(88,0,8,8,0,0,128,128)
 
 -- sky gradient
 if (false) then
 for y=0,127 do
  col=sget(88,(y+(y%4)*6) / 16)
  line(0,y,127,y,col)
 end
 end

 -- clouds behind mountains
 local x = t / 8
 x = x % 128
 local y=0
 mapdraw(16, 32, -x, y, 16, 16, 0)
 mapdraw(16, 32, 128-x, y, 16, 16, 0)

 
 local bgcol = 13 -- mountains
 pal(5,bgcol) pal(2,bgcol)
 pal(13,6) -- highlights 
 y = 0
 mapdraw (0, 32, 0, y, 16, 16, 0)
	pal()
 
 
 -- map and actors
	cam_x = mid(0,player.x*8-64,1024-128)

 if (player2 ~= nil) then
  cam_x = 
   mid(0,player2.x*8-64,1024-128) / 2 +
   cam_x / 2
 end
 
 --cam_y = mid(0,player.y*6-40,128)
 cam_y = 84
	camera (cam_x,cam_y)
 pal(12,0)	
	mapdraw (0,0,0,0,128,64,1)
 pal()
 foreach(sparkle, draw_sparkle)
	foreach(actor, draw_actor)
	
 -- forground map
--	mapdraw (0,0,0,0,128,64,2)

 -- player score
 camera(0,0)
 color(7)
 
 if (death_t > 60) then
  print("press button to restart",
   18-1,10-0,8+(t/4)%2)
  print("press button to restart",
   18,10,7)
 end
 
 if (false) then
  cursor(0,2)
  print("actors:"..count(actor))
  print("score:"..player.score)
  print(stat(1))
 end
end
