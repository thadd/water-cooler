function SoundManager(smURL,smID){
var SM2_COPYRIGHT = [
  'SoundManager 2: Javascript Sound for the Web',
  'http://schillmania.com/projects/soundmanager2/',
  'Copyright (c) 2008, Scott Schiller. All rights reserved.',
  'Code provided under the BSD License: http://schillmania.com/projects/soundmanager2/license.txt',
];
this.flashVersion=8;this.debugMode=true;this.useConsole=true;this.consoleOnly=false;this.waitForWindowLoad=false;this.nullURL='data/null.mp3';this.defaultOptions={'autoLoad':false,'stream':true,'autoPlay':false,'onid3':null,'onload':null,'whileloading':null,'onplay':null,'onpause':null,'onresume':null,'whileplaying':null,'onstop':null,'onfinish':null,'onbeforefinish':null,'onbeforefinishtime':5000,'onbeforefinishcomplete':null,'onjustbeforefinish':null,'onjustbeforefinishtime':200,'multiShot':true,'position':null,'pan':0,'volume':100};this.flash9Options={usePeakData:false,useWaveformData:false,useEQData:false};this.allowPolling=true;var self=this;this.version=null;this.versionNumber='V2.76a.20080808';this.movieURL=null;this.url=null;this.swfLoaded=false;this.enabled=false;this.o=null;this.id=(smID||'sm2movie');this.oMC=null;this.sounds=[];this.soundIDs=[];this.isIE=(navigator.userAgent.match(/MSIE/i));this.isSafari=(navigator.userAgent.match(/safari/i));this.debugID='soundmanager-debug';this._debugOpen=true;this._didAppend=false;this._appendSuccess=false;this._didInit=false;this._disabled=false;this._windowLoaded=false;this._hasConsole=(typeof console!='undefined'&&typeof console.log!='undefined');this._debugLevels=['log','info','warn','error'];this._defaultFlashVersion=8;this.features={peakData:false,waveformData:false,eqData:false};this.sandbox={'type':null,'types':{'remote':'remote (domain-based) rules','localWithFile':'local with file access (no internet access)','localWithNetwork':'local with network (internet access only, no local access)','localTrusted':'local, trusted (local + internet access)'},'description':null,'noRemote':null,'noLocal':null};this._setVersionInfo=function(){if(self.flashVersion!=8&&self.flashVersion!=9){alert('soundManager.flashVersion must be 8 or 9. "'+self.flashVersion+'" is invalid. Reverting to '+self._defaultFlashVersion+'.');self.flashVersion=self._defaultFlashVersion;}
self.version=self.versionNumber+(self.flashVersion==9?' (AS3/Flash 9)':' (AS2/Flash 8)');self.movieURL=(self.flashVersion==8?'soundmanager2.swf':'soundmanager2_flash9.swf');self.features.peakData=self.features.waveformData=self.features.eqData=(self.flashVersion==9);}
this._overHTTP=(document.location?document.location.protocol.match(/http/i):null);this._waitingforEI=false;this._initPending=false;this._tryInitOnFocus=(this.isSafari&&typeof document.hasFocus=='undefined');this._isFocused=(typeof document.hasFocus!='undefined'?document.hasFocus():null);this._okToDisable=!this._tryInitOnFocus;var flashCPLink='http://www.macromedia.com/support/documentation/en/flashplayer/help/settings_manager04.html';this.supported=function(){return(self._didInit&&!self._disabled);};this.getMovie=function(smID){return self.isIE?window[smID]:(self.isSafari?document.getElementById(smID)||document[smID]:document.getElementById(smID));};this.loadFromXML=function(sXmlUrl){try{self.o._loadFromXML(sXmlUrl);}catch(e){self._failSafely();return true;};};this.createSound=function(oOptions){if(!self._didInit)throw new Error('soundManager.createSound(): Not loaded yet - wait for soundManager.onload() before calling sound-related methods');if(arguments.length==2){oOptions={'id':arguments[0],'url':arguments[1]};};var thisOptions=self._mergeObjects(oOptions);if(self._idCheck(thisOptions.id,true)){return self.sounds[thisOptions.id];};self.sounds[thisOptions.id]=new SMSound(self,thisOptions);self.soundIDs[self.soundIDs.length]=thisOptions.id;try{if(self.flashVersion==8){self.o._createSound(thisOptions.id,thisOptions.onjustbeforefinishtime);}else{self.o._createSound(thisOptions.id,thisOptions.url,thisOptions.onjustbeforefinishtime,thisOptions.usePeakData,thisOptions.useWaveformData,thisOptions.useEQData);}}catch(e){self._failSafely();return true;};if(thisOptions.autoLoad||thisOptions.autoPlay)window.setTimeout(function(){self.sounds[thisOptions.id].load(thisOptions);},20);if(thisOptions.autoPlay){if(self.flashVersion==8){self.sounds[thisOptions.id].playState=1;}else{self.sounds[thisOptions.id].play();}}
return self.sounds[thisOptions.id];};this.destroySound=function(sID){if(!self._idCheck(sID))return false;for(var i=0;i<self.soundIDs.length;i++){if(self.soundIDs[i]==sID){self.soundIDs.splice(i,1);continue;};};self.sounds[sID].unload();self.sounds[sID].destruct();delete self.sounds[sID];};this.load=function(sID,oOptions){if(!self._idCheck(sID))return false;self.sounds[sID].load(oOptions);};this.unload=function(sID){if(!self._idCheck(sID))return false;self.sounds[sID].unload();};this.play=function(sID,oOptions){if(!self._idCheck(sID)){if(typeof oOptions!='Object')oOptions={url:oOptions};if(oOptions&&oOptions.url){oOptions.id=sID;self.createSound(oOptions);}else{return false;};};self.sounds[sID].play(oOptions);};this.start=this.play;this.setPosition=function(sID,nMsecOffset){if(!self._idCheck(sID))return false;self.sounds[sID].setPosition(nMsecOffset);};this.stop=function(sID){if(!self._idCheck(sID))return false;self.sounds[sID].stop();};this.stopAll=function(){for(var oSound in self.sounds){if(self.sounds[oSound]instanceof SMSound)self.sounds[oSound].stop();};};this.pause=function(sID){if(!self._idCheck(sID))return false;self.sounds[sID].pause();};this.resume=function(sID){if(!self._idCheck(sID))return false;self.sounds[sID].resume();};this.togglePause=function(sID){if(!self._idCheck(sID))return false;self.sounds[sID].togglePause();};this.setPan=function(sID,nPan){if(!self._idCheck(sID))return false;self.sounds[sID].setPan(nPan);};this.setVolume=function(sID,nVol){if(!self._idCheck(sID))return false;self.sounds[sID].setVolume(nVol);};this.mute=function(sID){if(!sID){var o=null;for(o in self.sounds){self.sounds[o].mute();}}else{if(!self._idCheck(sID))return false;self.sounds[sID].mute();}};this.unmute=function(sID){if(!sID){var o=null;for(o in self.sounds){self.sounds[o].unmute();}}else{if(!self._idCheck(sID))return false;self.sounds[sID].unmute();}};this.setPolling=function(bPolling){if(!self.o||!self.allowPolling)return false;self.o._setPolling(bPolling);};this.disable=function(){if(self._disabled)return false;self._disabled=true;for(var i=self.soundIDs.length;i--;){self._disableObject(self.sounds[self.soundIDs[i]]);};self.initComplete();self._disableObject(self);};this.getSoundById=function(sID,suppressDebug){if(!sID)throw new Error('SoundManager.getSoundById(): sID is null/undefined');var result=self.sounds[sID];if(!result&&!suppressDebug){};return result;};this.onload=function(){};this.onerror=function(){};this._idCheck=this.getSoundById;this._disableObject=function(o){for(var oProp in o){if(typeof o[oProp]=='function'&&typeof o[oProp]._protected=='undefined')o[oProp]=function(){return false;};};oProp=null;};this._failSafely=function(){var fpgssTitle='You may need to whitelist this location/domain eg. file:///C:/ or C:/ or mysite.com, or set ALWAYS ALLOW under the Flash Player Global Security Settings page. The latter is probably less-secure.';var flashCPL='<a href="'+flashCPLink+'" title="'+fpgssTitle+'">view/edit</a>';var FPGSS='<a href="'+flashCPLink+'" title="Flash Player Global Security Settings">FPGSS</a>';if(!self._disabled){self.disable();};};this._normalizeMovieURL=function(smURL){if(smURL){if(smURL.match(/\.swf/)){smURL=smURL.substr(0,smURL.lastIndexOf('.swf'));}
if(smURL.lastIndexOf('/')!=smURL.length-1){smURL=smURL+'/';}}
return(smURL&&smURL.lastIndexOf('/')!=-1?smURL.substr(0,smURL.lastIndexOf('/')+1):'./')+self.movieURL;}
this._createMovie=function(smID,smURL){if(self._didAppend&&self._appendSuccess)return false;if(window.location.href.indexOf('debug=1')+1)self.debugMode=true;self._didAppend=true;self._setVersionInfo();self.url=self._normalizeMovieURL(smURL?smURL:self.url);smURL=self.url;var htmlEmbed='<embed name="'+smID+'" id="'+smID+'" src="'+smURL+'" width="1" height="1" quality="high" allowScriptAccess="always" pluginspage="http://www.macromedia.com/go/getflashplayer" type="application/x-shockwave-flash"></embed>';var htmlObject='<object id="'+smID+'" data="'+smURL+'" type="application/x-shockwave-flash" width="1" height="1"><param name="movie" value="'+smURL+'" /><param name="AllowScriptAccess" value="always" /><!-- --></object>';html=(!self.isIE?htmlEmbed:htmlObject);var toggleElement='<div id="'+self.debugID+'-toggle" style="position:fixed;_position:absolute;right:0px;bottom:0px;_top:0px;width:1.2em;height:1.2em;line-height:1.2em;margin:2px;padding:0px;text-align:center;border:1px solid #999;cursor:pointer;background:#fff;color:#333;z-index:706" title="Toggle SM2 debug console" onclick="soundManager._toggleDebug()">-</div>';var debugHTML='<div id="'+self.debugID+'" style="display:'+(self.debugMode&&((!self._hasConsole||!self.useConsole)||(self.useConsole&&self._hasConsole&&!self.consoleOnly))?'block':'none')+';opacity:0.85"></div>';var appXHTML='soundManager._createMovie(): appendChild/innerHTML set failed. May be app/xhtml+xml DOM-related.';var sHTML='<div style="position:absolute;left:-256px;top:-256px;width:1px;height:1px" class="movieContainer">'+html+'</div>'+(self.debugMode&&((!self._hasConsole||!self.useConsole)||(self.useConsole&&self._hasConsole&&!self.consoleOnly))&&!document.getElementById(self.debugID)?'x'+debugHTML+toggleElement:'');var oTarget=(document.body?document.body:(document.documentElement?document.documentElement:document.getElementsByTagName('div')[0]));if(oTarget){self.oMC=document.createElement('div');self.oMC.className='movieContainer';self.oMC.style.position='absolute';self.oMC.style.left='-256px';self.oMC.style.width='1px';self.oMC.style.height='1px';try{oTarget.appendChild(self.oMC);self.oMC.innerHTML=html;self._appendSuccess=true;}catch(e){throw new Error(appXHTML);};if(!document.getElementById(self.debugID)&&((!self._hasConsole||!self.useConsole)||(self.useConsole&&self._hasConsole&&!self.consoleOnly))){var oDebug=document.createElement('div');oDebug.id=self.debugID;oDebug.style.display=(self.debugMode?'block':'none');if(self.debugMode){try{var oD=document.createElement('div');oTarget.appendChild(oD);oD.innerHTML=toggleElement;}catch(e){throw new Error(appXHTML);};};oTarget.appendChild(oDebug);};oTarget=null;};};this._writeDebug=function(sText,sType,bTimestamp){};this._writeDebug._protected=true;this._writeDebugAlert=function(sText){alert(sText);};this._toggleDebug=function(){var o=document.getElementById(self.debugID);var oT=document.getElementById(self.debugID+'-toggle');if(!o)return false;if(self._debugOpen){oT.innerHTML='+';o.style.display='none';}else{oT.innerHTML='-';o.style.display='block';};self._debugOpen=!self._debugOpen;};this._toggleDebug._protected=true;this._debug=function(){};this._mergeObjects=function(oMain,oAdd){var o1={};for(var i in oMain){o1[i]=oMain[i];}
var o2=(typeof oAdd=='undefined'?self.defaultOptions:oAdd);for(var o in o2){if(typeof o1[o]=='undefined')o1[o]=o2[o];};return o1;};this.createMovie=function(sURL){if(sURL)self.url=sURL;self._initMovie();};this.go=this.createMovie;this._initMovie=function(){if(self.o)return false;self.o=self.getMovie(self.id);if(!self.o){self._createMovie(self.id,self.url);self.o=self.getMovie(self.id);};};this.waitForExternalInterface=function(){if(self._waitingForEI)return false;self._waitingForEI=true;if(self._tryInitOnFocus&&!self._isFocused){return false;};setTimeout(function(){if(!self._didInit&&self._okToDisable)self._failSafely();},750);};this.handleFocus=function(){if(self._isFocused||!self._tryInitOnFocus)return true;self._okToDisable=true;self._isFocused=true;if(self._tryInitOnFocus){window.removeEventListener('mousemove',self.handleFocus,false);};self._waitingForEI=false;setTimeout(self.waitForExternalInterface,500);if(window.removeEventListener){window.removeEventListener('focus',self.handleFocus,false);}else if(window.detachEvent){window.detachEvent('onfocus',self.handleFocus);};};this.initComplete=function(){if(self._didInit)return false;self._didInit=true;if(self._disabled){self.onerror.apply(window);return false;};if(self.waitForWindowLoad&&!self._windowLoaded){if(window.addEventListener){window.addEventListener('load',self.initUserOnload,false);}else if(window.attachEvent){window.attachEvent('onload',self.initUserOnload);};return false;}else{self.initUserOnload();};};this.initUserOnload=function(){try{self.onload.apply(window);}catch(e){setTimeout(function(){throw new Error(e)},20);return false;};};this.init=function(){self._initMovie();if(self._didInit){return false;};if(window.removeEventListener){window.removeEventListener('load',self.beginDelayedInit,false);}else if(window.detachEvent){window.detachEvent('onload',self.beginDelayedInit);};try{self.o._externalInterfaceTest(false);self.setPolling(true);if(!self.debugMode)self.o._disableDebug();self.enabled=true;}catch(e){self._failSafely();self.initComplete();return false;};self.initComplete();};this.beginDelayedInit=function(){self._windowLoaded=true;setTimeout(self.waitForExternalInterface,500);setTimeout(self.beginInit,20);};this.beginInit=function(){if(self._initPending)return false;self.createMovie();self._initMovie();self._initPending=true;return true;};this.domContentLoaded=function(){if(document.removeEventListener)document.removeEventListener('DOMContentLoaded',self.domContentLoaded,false);self.go();};this._externalInterfaceOK=function(){if(self.swfLoaded)return false;self.swfLoaded=true;self._tryInitOnFocus=false;if(self.isIE){setTimeout(self.init,100);}else{self.init();};};this._setSandboxType=function(sandboxType){var sb=self.sandbox;sb.type=sandboxType;sb.description=sb.types[(typeof sb.types[sandboxType]!='undefined'?sandboxType:'unknown')];if(sb.type=='localWithFile'){sb.noRemote=true;sb.noLocal=false;}else if(sb.type=='localWithNetwork'){sb.noRemote=false;sb.noLocal=true;}else if(sb.type=='localTrusted'){sb.noRemote=false;sb.noLocal=false;};};this.destruct=function(){self.disable();};function SMSound(oSM,oOptions){var self=this;var sm=oSM;this.sID=oOptions.id;this.url=oOptions.url;this.options=sm._mergeObjects(oOptions);this.instanceOptions=this.options;this._debug=function(){if(sm.debugMode){var stuff=null;var msg=[];var sF=null;var sfBracket=null;var maxLength=64;for(stuff in self.options){if(self.options[stuff]!=null){if(self.options[stuff]instanceof Function){sF=self.options[stuff].toString();sF=sF.replace(/\s\s+/g,' ');sfBracket=sF.indexOf('{');msg[msg.length]=' '+stuff+': {'+sF.substr(sfBracket+1,(Math.min(Math.max(sF.indexOf('\n')-1,maxLength),maxLength))).replace(/\n/g,'')+'... }';}else{msg[msg.length]=' '+stuff+': '+self.options[stuff];};};};};};this._debug();this.id3={};self.resetProperties=function(bLoaded){self.bytesLoaded=null;self.bytesTotal=null;self.position=null;self.duration=null;self.durationEstimate=null;self.loaded=false;self.loadSuccess=null;self.playState=0;self.paused=false;self.readyState=0;self.didBeforeFinish=false;self.didJustBeforeFinish=false;self.instanceOptions={};self.instanceCount=0;self.peakData={left:0,right:0};self.waveformData=[];self.eqData=[];};self.resetProperties();this.load=function(oOptions){self.instanceOptions=sm._mergeObjects(oOptions);if(typeof self.instanceOptions.url=='undefined')self.instanceOptions.url=self.url;if(self.instanceOptions.url==self.url&&self.readyState!=0&&self.readyState!=2){return false;}
self.loaded=false;self.loadSuccess=null;self.readyState=1;self.playState=(oOptions.autoPlay?1:0);try{if(sm.flashVersion==8){sm.o._load(self.sID,self.instanceOptions.url,self.instanceOptions.stream,self.instanceOptions.autoPlay,(self.instanceOptions.whileloading?1:0));}else{sm.o._load(self.sID,self.instanceOptions.url,self.instanceOptions.stream?true:false,self.instanceOptions.autoPlay?true:false);};}catch(e){};};this.unload=function(){self.setPosition(0);sm.o._unload(self.sID,sm.nullURL);self.resetProperties();};this.destruct=function(){sm.o._destroySound(self.sID);}
this.play=function(oOptions){if(!oOptions)oOptions={};self.instanceOptions=sm._mergeObjects(oOptions,self.instanceOptions);self.instanceOptions=sm._mergeObjects(self.instanceOptions,self.options);if(self.playState==1){var allowMulti=self.instanceOptions.multiShot;if(!allowMulti){return false;}else{};};if(!self.loaded){if(self.readyState==0){self.instanceOptions.stream=true;self.instanceOptions.autoPlay=true;self.load(self.instanceOptions);}else if(self.readyState==2){return false;}else{};}else{};if(self.paused){self.resume();}else{self.playState=1;if(!self.instanceCount||sm.flashVersion==9)self.instanceCount++;self.position=(typeof self.instanceOptions.position!='undefined'&&!isNaN(self.instanceOptions.position)?self.instanceOptions.position:0);if(self.instanceOptions.onplay)self.instanceOptions.onplay.apply(self);self.setVolume(self.instanceOptions.volume);self.setPan(self.instanceOptions.pan);sm.o._start(self.sID,self.instanceOptions.loop||1,(sm.flashVersion==9?self.position:self.position/1000));};};this.start=this.play;this.stop=function(bAll){if(self.playState==1){self.playState=0;self.paused=false;if(self.instanceOptions.onstop)self.instanceOptions.onstop.apply(self);sm.o._stop(self.sID,bAll);self.instanceCount=0;self.instanceOptions={};};};this.setPosition=function(nMsecOffset){self.instanceOptions.position=nMsecOffset;sm.o._setPosition(self.sID,(sm.flashVersion==9?self.instanceOptions.position:self.instanceOptions.position/1000),(self.paused||!self.playState));};this.pause=function(){if(self.paused)return false;self.paused=true;sm.o._pause(self.sID);if(self.instanceOptions.onpause)self.instanceOptions.onpause.apply(self);};this.resume=function(){if(!self.paused)return false;self.paused=false;sm.o._pause(self.sID);if(self.instanceOptions.onresume)self.instanceOptions.onresume.apply(self);};this.togglePause=function(){if(!self.playState){self.play({position:(sm.flashVersion==9?self.position:self.position/1000)});return false;};if(self.paused){self.resume();}else{self.pause();};};this.setPan=function(nPan){if(typeof nPan=='undefined')nPan=0;sm.o._setPan(self.sID,nPan);self.instanceOptions.pan=nPan;};this.setVolume=function(nVol){if(typeof nVol=='undefined')nVol=100;sm.o._setVolume(self.sID,nVol);self.instanceOptions.volume=nVol;};this.mute=function(){sm.o._setVolume(self.sID,0);};this.unmute=function(){sm.o._setVolume(self.sID,self.instanceOptions.volume);};this._whileloading=function(nBytesLoaded,nBytesTotal,nDuration){self.bytesLoaded=nBytesLoaded;self.bytesTotal=nBytesTotal;self.duration=Math.floor(nDuration);self.durationEstimate=parseInt((self.bytesTotal/self.bytesLoaded)*self.duration);if(self.readyState!=3&&self.instanceOptions.whileloading)self.instanceOptions.whileloading.apply(self);};this._onid3=function(oID3PropNames,oID3Data){var oData=[];for(var i=0,j=oID3PropNames.length;i<j;i++){oData[oID3PropNames[i]]=oID3Data[i];};self.id3=sm._mergeObjects(self.id3,oData);if(self.instanceOptions.onid3)self.instanceOptions.onid3.apply(self);};this._whileplaying=function(nPosition,oPeakData,oWaveformData,oEQData){if(isNaN(nPosition)||nPosition==null)return false;self.position=nPosition;if(self.instanceOptions.usePeakData&&typeof oPeakData!='undefined'&&oPeakData){self.peakData={left:oPeakData.leftPeak,right:oPeakData.rightPeak};};if(self.instanceOptions.useWaveformData&&typeof oWaveformData!='undefined'&&oWaveformData){self.waveformData=oWaveformData;};if(self.instanceOptions.useEQData&&typeof oEQData!='undefined'&&oEQData){self.eqData=oEQData;};if(self.playState==1){if(self.instanceOptions.whileplaying)self.instanceOptions.whileplaying.apply(self);if(self.loaded&&self.instanceOptions.onbeforefinish&&self.instanceOptions.onbeforefinishtime&&!self.didBeforeFinish&&self.duration-self.position<=self.instanceOptions.onbeforefinishtime){self._onbeforefinish();};};};this._onload=function(bSuccess){bSuccess=(bSuccess==1?true:false);if(!bSuccess){if(sm.sandbox.noRemote==true){};if(sm.sandbox.noLocal==true){};};self.loaded=bSuccess;self.loadSuccess=bSuccess;self.readyState=bSuccess?3:2;if(self.instanceOptions.onload){self.instanceOptions.onload.apply(self);};};this._onbeforefinish=function(){if(!self.didBeforeFinish){self.didBeforeFinish=true;if(self.instanceOptions.onbeforefinish)self.instanceOptions.onbeforefinish.apply(self);};};this._onjustbeforefinish=function(msOffset){if(!self.didJustBeforeFinish){self.didJustBeforeFinish=true;if(self.instanceOptions.onjustbeforefinish)self.instanceOptions.onjustbeforefinish.apply(self);};};this._onfinish=function(){self.playState=0;self.paused=false;if(self.instanceOptions.onfinish)self.instanceOptions.onfinish.apply(self);if(self.instanceOptions.onbeforefinishcomplete)self.instanceOptions.onbeforefinishcomplete.apply(self);self.didBeforeFinish=false;self.didJustBeforeFinish=false;if(self.instanceCount){self.instanceCount--;if(!self.instanceCount){self.instanceCount=0;self.instanceOptions={};}}};};if(this.flashVersion==9){}
if(window.addEventListener){window.addEventListener('focus',self.handleFocus,false);window.addEventListener('load',self.beginDelayedInit,false);window.addEventListener('beforeunload',self.destruct,false);if(self._tryInitOnFocus)window.addEventListener('mousemove',self.handleFocus,false);}else if(window.attachEvent){window.attachEvent('onfocus',self.handleFocus);window.attachEvent('onload',self.beginDelayedInit);window.attachEvent('beforeunload',self.destruct);}else{soundManager.onerror();soundManager.disable();};if(document.addEventListener)document.addEventListener('DOMContentLoaded',self.domContentLoaded,false);};var soundManager=new SoundManager();