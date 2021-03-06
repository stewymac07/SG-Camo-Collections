﻿package sg.camo.greensock.transitions
{
	import com.greensock.core.TweenCore;
	import com.greensock.TweenLite;
	import sg.camo.greensock.EasingMethods;
	import sg.camo.interfaces.IDestroyable;
	import sg.camo.interfaces.ITransitionModule;
	import sg.camo.greensock.GSPluginVars;
	import sg.camo.greensock.CreateGSTweenVars;
	
	/**
	 * A GS tween transitioning scheme over a particular target object
	 * @author Glenn Ko
	 */
	public class GSTransition implements ITransitionModule, IDestroyable
	{
		protected var _target:Object;
		protected var _inVars:Object;
		protected var _outVars:Object;
		protected var _initVars:Object;
		protected var _outVarsInterrupt:Object;
		
		protected var _pluginVars:GSPluginVars;
		
		public var durationIn:Number = .3;
		public var durationOut:Number = .3;

		public var durationOutInterrupt:Number = 0;
		public var reverseOnOut:Boolean = false;
		
		public var reverseOnInterrupt:Boolean = false; // to be deperciate

		
		protected var _curTween:TweenCore;
		protected var _tweenClass:Class;
		

		
		
	
		
		protected var _restoreVars:Object = { };
		
		/**
		 * Constructor
		 * @param	target		Required. The targetted instance.
		 * @param   tweenClass	The optional custom TweenCore class to use. (eg. TweenMax)
		 * @param	pluginVars	The set of GSPluginVars to allow for referencing. If left undefined, uses singleton reference of GSPluginVars. 
		 */
		public function GSTransition(target:Object, tweenClass:Class= null, pluginVars:GSPluginVars=null) 
		{
			if (target == null) return;
			_target = target;
			
			_pluginVars = pluginVars;
			_tweenClass = tweenClass || TweenLite;
			
		}
		
		// -- ITransitionModule
		
		public function get transitionInPayload():* {
			
			if (_initVars) (new _tweenClass(_target, .1, CreateGSTweenVars.createVarsFromObject(_initVars, _pluginVars) ) as TweenCore).complete();


			
			if (checkIsReversible(_curTween)) return _curTween;
			_curTween = createTweenFromVars(_inVars || {}, durationIn);  // _inVars ? _inVars as TweenCore ||  : null
		
			return _curTween;
		}
		


		
		public function get transitionOutPayload():* { 
			//if (checkIsReversible(_curTween)) return _curTween;
			if (_curTween == null) {
				if (_outVars) _curTween = createTweenFromVars(_outVars, durationOut);
				else return null;
			}
			var hasEnded:Boolean =  _curTween.totalDuration == _curTween.totalTime;
			
			if ( reverseOnOut) {
				
				//if (_curTween.totalTime > 0 ) { //&& _curTween.totalDuration == _curTween.totalTime
					
					_curTween.pause();
					
					_curTween =  new _tweenClass(_curTween, durationOutInterrupt || _curTween.totalTime, { currentTime:0 } ); 
					if (hasEnded && _outVars) {
						for (var i:String in _outVars) {
							_curTween.vars[i] = _outVars[i];
						}
					}
					else if (_outVarsInterrupt) {
						for (i in _outVarsInterrupt ) {
							
							_curTween.vars[i] = _outVarsInterrupt[i];
						}
					}
					
					return _curTween;
				//}
			}
			
			_curTween =  !hasEnded && _outVarsInterrupt ?  createTweenFromVars(_outVarsInterrupt, durationOutInterrupt || _curTween.totalTime) : _outVars ? createTweenFromVars(_outVars, durationOut) : null;
		
			return _curTween;	
		}
		
		public function get transitionType():* {
			return TweenCore;
		}
		
		protected function reverseVars(vars:Object):Object {
			// duplicated from TweenLite.from
			vars.runBackwards = true;
			if (!("immediateRender" in vars)) {
				vars.immediateRender = true;
			}
			return vars;
		}
		
		// -- Protected helpers
		
		protected function createTweenFromVars(vars:Object, duration:Number):TweenCore {
			return new _tweenClass(_target, duration, vars) as TweenCore;
		}
		

		
		/** @private  To be depeciated
		*/
		protected function checkIsReversible(tw:TweenCore):Boolean {
			if (tw==null || !reverseOnInterrupt) return false;
			if (_curTween.totalTime > 0 && _curTween.totalTime < _curTween.totalDuration  ) {
		
				tw.reverse(false);
				
				return true;
			}
			return false;
		}
		
		// -- Public methods
		
		public function set initVars(obj:Object):void {
			
			for (var i:String in obj) {
				if (i.charAt(0) === "*") {  // cleanup relative values. initVars only supports absolute values
					var prop:String = i.substr(1);
					obj[prop] = String( _target[prop] + Number(obj[i]) );
					delete obj[i];
				}
			}
			_initVars = obj;	
		}
		
		public function set restoreVars(obj:Object):void {
			_restoreVars = CreateGSTweenVars.createVarsFromObject(obj, _pluginVars);
		}
		

		
		public function set duration(val:Number):void {
			durationIn = val;
			durationOut = val;
		}
		
		public function set fromVars(obj:Object):void {
			var obj:Object = CreateGSTweenVars.createVarsFromObject(obj, _pluginVars);
		
			//_inVars = _tweenClass["from"](_target, durationIn, obj );
			_inVars = obj;
			_inVars.runBackwards = true;
			_inVars.immediateRender = true;
		}
		
		public function set setVars(obj:Object):void {
			(new _tweenClass(_target, .1, CreateGSTweenVars.createVarsFromObject(obj, _pluginVars) ) as TweenCore).complete();
		}
		
		
		
		public function set inVars(obj:Object):void {
			_inVars = CreateGSTweenVars.createVarsFromObject( obj, _pluginVars );
		}
		
		public function set outVars(obj:Object):void {
			_outVars = CreateGSTweenVars.createVarsFromObject( obj, _pluginVars );
		}
		
		public function set outVarsInterrupt(obj:Object):void {
			_outVarsInterrupt = CreateGSTweenVars.createVarsFromObject( obj, _pluginVars );
		}
			
				
		
		
		// -- IDestroyable
		
		public function destroy():void {
			if (_target == null) return;
			for (var i:String in _restoreVars) {
				_target[i] = _restoreVars[i];
			}
			if (_curTween) {
				_curTween.pause();
				_curTween = null;
			}

		}


		
	}

}