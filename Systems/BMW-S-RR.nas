###############################################################################################
#		Lake of Constance Hangar :: M.Kraus
#		BMW-S-RR for Flightgear September 2014
#		This file is licenced under the terms of the GNU General Public Licence V2 or later
###############################################################################################
var config_dlg = gui.Dialog.new("/sim/gui/dialogs/config/dialog", getprop("/sim/aircraft-dir")~"/Systems/config.xml");
var hangoffspeed = props.globals.initNode("/controls/hang-off-speed",80,"DOUBLE");
var hangoffhdg = props.globals.initNode("/controls/hang-off-hdg",0,"DOUBLE");
var waiting = props.globals.initNode("/controls/waiting",0,"DOUBLE");

################## Little Help Window on bottom of screen #################
var help_win = screen.window.new( 0, 0, 1, 5 );
help_win.fg = [1,1,1,1];

var messenger = func{
help_win.write(arg[0]);
}

var help_win_red = screen.window.new( 768, 512, 10, 5 );
help_win_red.fg = [1,0,0,1];

var messenger_red = func{
help_win_red.write(arg[0]);
}

#----- view correction and steering helper ------
# loop for fork control
setprop("/controls/flight/fork",0.0);
var f = props.globals.getNode("/controls/flight/fork");

var forkcontrol = func{
    var r = getprop("/controls/flight/rudder") or 0;
	var ms = getprop("/devices/status/mice/mouse/mode") or 0;
	var bl = getprop("/controls/gear/brake-left") or 0;
	var bs = getprop("/instrumentation/airspeed-indicator/indicated-speed-kt") or 0;
	if (ms == 1) {
		if(getprop("/devices/status/mice/mouse/button")==1){
			f.setValue(r);
		}
	}else{
		f.setValue(r);
	}
	if(bs > 38){
		setprop("/controls/gear/brake-front", bl);
	}else{
		setprop("/controls/gear/brake-front", 0);
	}
	
	# shoulder view helper
	var cv = getprop("sim/current-view/view-number") or 0;
	var apos = getprop("/devices/status/keyboard/event/key") or 0;
	var press = getprop("/devices/status/keyboard/event/pressed") or 0;
	var du = getprop("/controls/BMW-S-RR/driver-up") or 0;
	#helper turn shoulder to look back
	if(cv == 0 and !du){
		if(apos == 49 and press){
			setprop("/sim/current-view/heading-offset-deg", 155);
			setprop("/controls/BMW-S-RR/driver-looks-back",1);
		}else if(apos == 50 and press){
			setprop("/sim/current-view/heading-offset-deg", -155);
			setprop("/controls/BMW-S-RR/driver-looks-back-right",1);
		}else{
			var hdgpos = 0;
		    var posi = getprop("/controls/flight/aileron-manual") or 0;
		  	if(posi > 0.0001 and getprop("/controls/hangoff") == 1){
				hdgpos = 360 - 60*posi;
				hdgpos = (hdgpos < 340) ? 340 : hdgpos;
		  		setprop("/sim/current-view/goal-heading-offset-deg", hdgpos);
		  	}else if (posi < -0.0001 and getprop("/controls/hangoff") == 1){
				hdgpos = 60*abs(posi);
				hdgpos = (hdgpos > 20) ? 20 : hdgpos;
		  		setprop("/sim/current-view/goal-heading-offset-deg", hdgpos);
			}else if (posi > 0 and posi < 0.0001 and getprop("/controls/hangoff") == 1){
				setprop("/sim/current-view/goal-heading-offset-deg", 360);
			}else{
				setprop("/sim/current-view/goal-heading-offset-deg", 0);
			}
			setprop("/controls/BMW-S-RR/driver-looks-back",0);
			setprop("/controls/BMW-S-RR/driver-looks-back-right",0);
		}
	}
	
	# distance calculator helper
	if(getprop("/instrumentation/BMW-S-RR/speed-indicator/selection")){
		setprop("/instrumentation/BMW-S-RR/distance-calculator/miles", getprop("/instrumentation/BMW-S-RR/distance-calculator/mzaehler")*0.621371192); # miles on bike
		setprop("/instrumentation/BMW-S-RR/distance-calculator/dmiles", getprop("/instrumentation/BMW-S-RR/distance-calculator/dmzaehler")*0.621371192); # miles a day
	}else{
		setprop("/instrumentation/BMW-S-RR/distance-calculator/miles", getprop("/instrumentation/BMW-S-RR/distance-calculator/mzaehler")); # km on bike
		setprop("/instrumentation/BMW-S-RR/distance-calculator/dmiles", getprop("/instrumentation/BMW-S-RR/distance-calculator/dmzaehler")); # km a day
	}
	
	settimer(forkcontrol, 0);
};

forkcontrol();

setlistener("/devices/status/mice/mouse/button", func (state){
    var state = state.getBoolValue();
	# helper for the steering
	var ms = getprop("/devices/status/mice/mouse/mode") or 0;
	if (ms == 1 and state == 1) {
		controls.flapsDown(-1);
	}
},0,1);

setlistener("/devices/status/mice/mouse/button[2]", func (state){
    var state = state.getBoolValue();
	# helper for the steering
	var ms = getprop("/devices/status/mice/mouse/mode") or 0;
	if (ms == 1 and state == 1) {
		controls.flapsDown(1);
	}
},0,1);


setlistener("/controls/flight/aileron", func (position){
    var position = position.getValue();
	# helper for the steering
	var ms = getprop("/devices/status/mice/mouse/mode") or 0;
	if (ms == 1) {
		if(getprop("/devices/status/mice/mouse/button")==1){
			setprop("/controls/flight/aileron-manual",position*3);
		}else{
			f.setValue(position*0.65);
			setprop("/controls/flight/aileron-manual", position*0.75);
		}
		
	}else{
		var np = math.round(position*position*position*100);
		np = np/100;
		interpolate("/controls/flight/aileron-manual", np,0.1);
	}
});

setlistener("/surface-positions/left-aileron-pos-norm", func{

	var cvnr = getprop("sim/current-view/view-number") or 0;
	var omm = getprop("/controls/BMW-S-RR/old-mens-mode") or 0;
    var position = getprop("/controls/flight/aileron-manual") or 0;
	if(position >= 0){
		position = (position > 0.4) ? 0.4 : position;
	}else{
		position = (position < -0.4) ? -0.4 : position;
	}
	
	var driverpos = getprop("/controls/BMW-S-RR/driver-up") or 0;
	var driverview = 0.6*driverpos;
	driverview = (driverview == 0) ? -0.1 : driverview;	
	
	if (omm){
		if(cvnr == 0){
			setprop("/sim/current-view/x-offset-m", math.sin(position*1.6)*(1.36+driverpos/5));
			setprop("/sim/current-view/y-offset-m", math.cos(position*1.9)*(1.36+driverpos/4));
			setprop("/sim/current-view/z-offset-m",driverview);	
		} 
	}else{
		if(cvnr == 0){
			var godown = getprop("/instrumentation/airspeed-indicator/indicated-speed-kt") or 0;
			var lookup = getprop("/controls/gear/brake-right") or 0;
			var onwork = getprop("/controls/hangoff") or 0;
			if(godown < hangoffspeed.getValue()){
				var factor = (position <= 0)? -0.6 : 0.6;
				factor = (abs(factor) > abs(position)) ? position : factor;
				if(onwork == 0){
					settimer(func{setprop("/controls/hangoff",1)},0.1);
					interpolate("/sim/current-view/x-offset-m", math.sin(factor*1.8)*(1.34+driverpos/5),0.1);
					interpolate("/sim/current-view/y-offset-m", math.cos(factor*2.1)*(1.36 - godown/1300 + lookup/12 + driverpos/4),0.1);
				}else{
					setprop("/sim/current-view/x-offset-m", math.sin(factor*1.8)*(1.34+driverpos/5));
					setprop("/sim/current-view/y-offset-m", math.cos(factor*2.1)*(1.36 - godown/1300 + lookup/12 + driverpos/4));
				}
			}else{
				if(onwork == 1){
					interpolate("/sim/current-view/x-offset-m", math.sin(position*1.6)*(1.3+driverpos/5),0.1);
					interpolate("/sim/current-view/y-offset-m", math.cos(position*1.9)*(1.36 - godown/1500 + lookup/12 + driverpos/4),0.1);
					settimer(func{setprop("/controls/hangoff",0)},0.1);
				}else{
					setprop("/sim/current-view/x-offset-m", math.sin(position*1.6)*(1.3+driverpos/5));
					setprop("/sim/current-view/y-offset-m", math.cos(position*1.9)*(1.36 - godown/1500 + lookup/12 + driverpos/4));
				}
			}
			setprop("/sim/current-view/z-offset-m",driverview);	
		}    
	}
});


setlistener("/controls/flight/elevator", func (position){
    var position = position.getValue();
	# helper for braking
	var ms = getprop("/devices/status/mice/mouse/mode") or 0;
	if (ms == 1 and position < 0) {
		setprop("/controls/gear/brake-left", abs(position));
		setprop("/controls/gear/brake-right", abs(position));
	}
	if (ms == 1 and position > 0) {
		setprop("/controls/gear/brake-left", 0);
		setprop("/controls/gear/brake-right", 0);
	}
	
	# helper for throtte on throttle axis or elevator
	var se = getprop("/controls/flight/select-throttle-input") or 0;
	if (ms == 0){
		if(se == 1 and position >= 0) setprop("/controls/flight/throttle-input", position);
		if(se == 0){
			position = (position < 0) ? abs(position) : 0;
			vortrieb = getprop("/engines/engine/propulsion") or 0;
			setprop("/sim/weight[1]/weight-lb", position*400*vortrieb);
		}
	} 
	if (ms == 1 and position >= 0) setprop("/controls/flight/throttle-input", position*4);
	
	
	
},0,1);


setlistener("/controls/engines/engine[0]/throttle", func (position){
    var position = position.getValue();
	
	# helper for throtte on throttle axis or elevator
	var ms = getprop("/devices/status/mice/mouse/mode") or 0;
	var se = getprop("/controls/flight/select-throttle-input") or 0;
	if (ms == 0 and se == 0 and position >= 0) setprop("/controls/flight/throttle-input", position*position);
},0,1);

#----- speed meter selection ------

setlistener("/gear/gear/rollspeed-ms", func (speed){
    var speed = speed.getValue();
	if(getprop("/instrumentation/BMW-S-RR/speed-indicator/selection")){
		if(speed > 0.1){
			setprop("/instrumentation/BMW-S-RR/speed-indicator/speed-meter", speed*3600/1000*0.621371); # mph
		}else{
			setprop("/instrumentation/BMW-S-RR/speed-indicator/speed-meter", 0);
		}
	}else{
		if(speed > 0.1){
			setprop("/instrumentation/BMW-S-RR/speed-indicator/speed-meter", speed*3600/1000); # km/h
		}else{
			setprop("/instrumentation/BMW-S-RR/speed-indicator/speed-meter", 0);
		}
	}
});


setlistener("/instrumentation/BMW-S-RR/speed-indicator/speed-limiter", func (sl){
	help_win.write(sprintf("Speed Limit: %.0f", sl.getValue()));
},1,0);

#----- brake and holder control ------

setlistener("/controls/gear/brake-parking", func (pb){
    var pb = pb.getBoolValue();
	
    if (pb != nil and pb){
		setprop("/controls/gear/gear-down", 1);
		setprop("/controls/gear/ready-to-race", 0);
	}else{
		setprop("/controls/gear/gear-down", 0);
		setprop("/controls/gear/ready-to-race", 1);
	}
});

setlistener("/controls/gear/gear-down", func (gd){
    var gd = gd.getBoolValue();
	
    if (gd != nil and gd){
		setprop("/controls/gear/brake-parking", 1);
		setprop("/controls/gear/ready-to-race", 0);
	}else{
		setprop("/controls/gear/brake-parking", 0);
		setprop("/controls/gear/ready-to-race", 1);
	}
});

#----- AUTOSTART  ------

# startup/shutdown functions
var startup = func
 {
	setprop("/controls/engines/engine/starter", 1);
	setprop("/engines/engine/cranking", 1);
 	settimer( func{
 	  if(getprop("/controls/engines/engine/starter") == 1){
	 		setprop("/controls/engines/engine/magnetos", 3);
	 		setprop("/controls/engines/engine/running", 1);
			setprop("/controls/engines/engine/starter", 0);
			setprop("/engines/engine/running", 1);
			setprop("/engines/engine/rpm", 2500);
			setprop("/engines/engine/cranking", 0);
		}
	}, 1);
 };
 
 var shutdown = func
  {
 	setprop("/controls/engines/engine/starter", 0);
	setprop("/controls/engines/engine/magnetos", 0);
	setprop("/controls/engines/engine/running", 0);
	interpolate("engines/engine/rpm", 0, 3);
	setprop("/engines/engine/magnetos", 0);
	setprop("/engines/engine/running", 0);
  };

# listener to activate these functions accordingly
setlistener("sim/model/start-idling", func()
 {
 var run1 = getprop("/engines/engine/running") or 0;
 
 if (run1 == 0)
  {
  	startup();
  }
 else
  {
  	shutdown();
  }
 }, 0, 0);
 
 #--------------------- Driver goes up and down smoothly ----------------
 setlistener("/controls/gear/brake-parking", func(p)
  {
 
  if (p.getValue() == 1)
   {
   		interpolate("/controls/BMW-S-RR/driver-up", 1, 0.8);
   }
  else
   {
   		interpolate("/controls/BMW-S-RR/driver-up", 0, 0.8);
   }
  }, 1, 0);
  
 #--------------------- Replace bike after crash ----------------
 setlistener("/devices/status/mice/mouse/button", func(b)
  {
  	var c = getprop("/sim/crashed") or 0;
	var p = getprop("/devices/status/keyboard/event/key/pressed") or 0;
	var k = getprop("/devices/status/keyboard/event/key") or 0;
 
  if (!b.getBoolValue() and k == 109)
   {
   		if( !waiting.getValue() ){
			setprop("/controls/waiting", 1);
			setprop("/devices/status/keyboard/event/key",60); # overwrite the key event
			setprop("sim/current-view/view-number", 1);
			shutdown();
			setprop("/sim/presets/latitude-deg",getprop("/sim/input/click/latitude-deg"));
			setprop("/sim/presets/longitude-deg", getprop("/sim/input/click/longitude-deg"));
			setprop("/sim/presets/altitude-ft", getprop("/sim/input/click/elevation-ft"));
			setprop("/controls/gear/gear-down", 1);
			setprop("/surface-positions/left-aileron-pos-norm", 0);
			setprop("/surface-positions/right-aileron-pos-norm", 0);
			setprop("sim/current-view/view-number", 0);
	
			fgcommand("reposition");

			# after restart set level
			settimer(func{setprop("consumables/fuel/tank/level-m3", getprop("/controls/fuel/remember-level"))},0.1);

			help_win_red.write("Is everything ok with you?");
		}else{
			help_win_red.write("5 SECONDS WAITING FOR REPLACEMENT!");
			settimer(func{setprop("/controls/waiting", 0)}, 3);
		}
   }
  }, 1, 1);

 

 
