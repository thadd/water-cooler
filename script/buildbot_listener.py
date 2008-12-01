#!/usr/bin/env python

# Buildbot client to send build notifications to the chat room

# Run this script as the mongrel user, or whatever owns the SQLite3 database.
# (This restriction is not necessary if the database is migrated to MySQL.)

__author__ = "Charles Lepple <clepple@raytheon.com>"
__version__ = '$Rev: 21248 $'[6:-2]
__date__ = '$Date: 2008-10-07 18:31:54 -0400 (Tue, 07 Oct 2008) $'[7:17]
__copyright__ = 'Copyright (C) 2008 Raytheon Company'

import os

from twisted.internet import reactor

# From contrib/bb_applet.py:
from twisted.spread import pb
from twisted.cred import credentials

from pprint import pprint

# This is the filesystem path to the production chat application:
chat_path='/web/adcon_chat'

SUCCESS, WARNINGS, FAILURE, SKIPPED, EXCEPTION = range(5)
Results = ["success", "warnings", "failure", "skipped", "exception"]

class ChatError(IOError):
    pass

def send_message(msg):
    os.chdir(chat_path)
    msg = str(msg).replace(r"'", r"\'")
    L = (os.path.join(chat_path, 'script/buildbot_message.sh'), str(msg))
    ret = os.spawnv(os.P_WAIT, L[0], L)
    print "  -> message '%s' sent, result = %d" % (str(msg),ret)
    if ret:
        raise ChatError, "Error %d when sending message %s" % (ret, repr(msg))

class BuildbotWatcher(pb.Referenceable):
    """This class connects to the Buildbot status port, and sends notifications to the chat room.
    """
    buildmaster = "svn.adcon.fal.us.ray.com", 9988
    buildbot_base_url = "http://svn.adcon.fal.us.ray.com:8010/"

    def __init__(self):
        self.connect()
        
    def url_for_buildername(self, buildername):
        return self.buildbot_base_url + 'builders/' + buildername
        
    def url_for_build_id(self, buildername, id):
        return self.buildbot_base_url + 'builders/' + buildername + ('/builds/%d' % id)
        
    def url_for_step(self, buildername, id, stepname):
        return self.url_for_build_id(buildername, id) + ('/steps/%s' % stepname)

    def link_for_buildername(self, buildername):
        return textile_url(self.url_for_buildername(buildername), buildername)
    
    def link_for_build_id(self, buildername, id):
        return textile_url(self.url_for_build_id(buildername, id), '%s #%d' % (buildername,id))
        
    def link_for_step(self, buildername, id, stepname):
        return textile_url(self.url_for_step(buildername, id, stepname), 'step %s' % stepname)

    def connect(self):
        print "Connecting..."
        host, port = self.buildmaster
        cf = pb.PBClientFactory()
        creds = credentials.UsernamePassword("statusClient", "clientpw")
        d = cf.login(creds)
        reactor.connectTCP(host, port, cf)
        d.addCallback(self.connected)
        return d
        
    def connected(self, ref):
        """Events to watch:
    
         - 'builders': only announce new/removed Builders
         - 'builds': also announce builderChangedState, buildStarted, and
           buildFinished
         - 'steps': also announce buildETAUpdate, stepStarted, stepFinished
         - 'logs': also announce stepETAUpdate, logStarted, logFinished
         - 'full': also announce log contents
        """
        print "connected"
        #send_message('connected.')
        ref.notifyOnDisconnect(self.disconnected)
        self.remote = ref
        # 2nd parameter to "subscribe" is the step update interval.
        self.remote.callRemote("subscribe", "steps", 60*5, self)
        print "subscribed"


    def disconnect(self):
        self.remote.broker.transport.loseConnection()
            
    def disconnected(self, *args):
        print "disconnected"

    def remote_builderAdded(self, buildername, builder):
        print "builderAdded", buildername
        
        def _got_build_results(results, buildername):
            print "last results for", buildername, ":", results
        def _got_build_text(text, buildername):
            print "results text for", buildername, ":", text
        def _got(build, buildername):
            #print "_got(build) called from remote_builderAdded"
            if build:
                d1 = build.callRemote("getResults")
                d1.addCallback(_got_build_results, buildername)
                d2 = build.callRemote("getText")
                d2.addCallback(_got_build_text, buildername)
        d = builder.callRemote("getLastFinishedBuild")
        d.addCallback(_got, buildername)

### Doesn't work, returns "None":
#        def _got_builds(s, name):
#            print "current builds for", name, ':', s
#             
#        d2 = builder.callRemote("getState")
#        d.addCallback(_got_builds, buildername)

    def remote_builderRemoved(self, buildername):
        print "builderRemoved", buildername

    def remote_builderChangedState(self, buildername, state, eta):
        """This method is called at startup, and when a builder changes state.
        
        "eta" is usually None, for whatever reason.
        
        """
        print "change", buildername, state, eta
        we_need_to_announce_builds_at_startup = False
        if state != 'idle' and we_need_to_announce_builds_at_startup:
            send_message('builder %s is %s' % (self.link_for_buildername(buildername), state))

    def remote_buildStarted(self, buildername, build):
        print "buildStarted", buildername, build
        #print "build methods:",
        #pprint(dir(build))
        #send_message('build started: %s' % self.link_for_buildername(buildername))

        def _got_build_reason(reason, id, buildername, build):
            reason = reason.rstrip()
            print "Reason for build on %s: '%s'" % (buildername, reason)
            if reason:
                send_message('build started: %s (why: %s)' % (self.link_for_build_id(buildername, id), reason))
            else:
                send_message('build started: %s' % (self.link_for_build_id(buildername, id)))

        
        def _got_build_id(id, buildername, build):
            print "build(%s) ID: %s" % (buildername, repr(id))
            d2 = build.callRemote("getReason")
            d2.addCallback(_got_build_reason, id, buildername, build)
            
        d = build.callRemote("getNumber")
        d.addCallback(_got_build_id, buildername, build)

    def remote_buildFinished(self, buildername, build, results):
        print "buildFinished", buildername, results
        def _got_build_reason(reason, id, results):
            reason = reason.rstrip()
            print "Reason for build on %s: '%s'" % (buildername, reason)
            if reason:
                send_message('build finished (%s): %s (why: %s)' % (Results[results], self.link_for_build_id(buildername, id), reason))
            else:
                send_message('build finished (%s): %s' % (Results[results], self.link_for_build_id(buildername, id)))
    
        
        def _got_build_id(id, results, build):
            ### see callbacks:
            # send_message('build finished: %s (%s)' % (self.link_for_build_id(buildername, id), Results[results]))
            d = build.callRemote("getReason")
            d.addCallback(_got_build_reason, id, results)
            
        def _got_build_results(results, build):
            print "results:", results
            d3 = build.callRemote("getNumber")
            d3.addCallback(_got_build_id, results, build)
            
        def _got_build_text(text):
            print "text:", text
            
        def _got_resp_users(users):
            print "users:", users
            
        if build:
            d1 = build.callRemote("getResults") # result code
            d1.addCallback(_got_build_results, build)
            d2 = build.callRemote("getText") # not so useful, usually "build successful"
            d2.addCallback(_got_build_text)

    def remote_buildETAUpdate(self, buildername, build, eta):
        # print "ETA", buildername, eta
        print "ETA:", buildername, prettytime(eta)
        send_message( "ETA for %s: %s" % (self.link_for_buildername(buildername), prettytime(eta)) )

    def remote_stepStarted(self, buildername, build, stepname, step):
        #print "stepStarted", buildername, stepname
        pass

    def remote_stepFinished(self, buildername, build, stepname, step, results):
        def _got_build_id(id, users, buildername, build, stepname, res):
            # send_message('build finished: %s (%s)' % (self.link_for_build_id(buildername, id), Results[results]))
            result = Results[res]
            step_link = self.link_for_step(buildername, id, stepname)
            for user in users:
                send_message("%(user)s: %(result) on %(steplink) - check build logs." % (locals()))
            
        def _got_resp_users(users, buildername, build, stepname, res):
            print "users responsible for %(stepname)s: %(users)s" % (locals())
            # If we have any users, send them a notification with a link to the log list page
            # like so: http://svn.adcon.fal.us.ray.com:8010/builders/ubuntu-gutsy-vsm-fruitbat/builds/138/steps/make_libunitconversions
            d = build.callRemote("getNumber")
            d.addCallback(_got_build_id, users, buildername, build, stepname, res)
    
        print "%(buildername)s: stepFinished(%(stepname)s) -> %(results)s" % (locals())
        res, rest = results
        #if not (res == SUCCESS):
        if res in (FAILURE, EXCEPTION):
            d = build.callRemote("getResponsibleUsers")
            d.addCallback(_got_resp_users, buildername, build, stepname, res)

def prettytime(eta):
    """Take in an ETA in seconds, and return a string describing that ETA in hours, minutes and seconds.
    
    >>> prettytime(1)
    '1 second'
    >>> prettytime(5)
    '5 seconds'
    >>> prettytime(65)
    '1 minute, 5 seconds'
    >>> prettytime(7285)
    '2 hours, 1 minute, 25 seconds'
    
    """
    ret = ''
    eta,eta_s = divmod(eta,60)
    eta,eta_m = divmod(eta,60)
    eta,eta_h = divmod(eta,60)
    if eta_h:
        if eta_h == 1:
            ret += '%d hour, ' % eta_h
        else:
            ret += '%d hours, ' % eta_h
    if eta_h or eta_m:
        if eta_m == 1:
            ret += '%d minute, ' % eta_m
        else:
            ret += '%d minutes, ' % eta_m
    if eta_s == 1:
        ret += '%d second' % eta_s
    else:
        ret += '%d seconds' % eta_s
    return ret

def textile_url(link, title):
    """Format a URL in Textile syntax.
    
    Parameters:
     - link: the URL
     - title: a string describing the URL
    
    >>> textile_url('http://www.example.org/', "Link to example.org")
    '"Link to example.org":http://www.example.org/'
    
    """
    return '"%s":%s' % (title, link)
    
def main(args=()):
    if '-t' in args or '--test' in args:
        import doctest
        doctest.testmod()
    else:
        watcher = BuildbotWatcher()
        reactor.run()
    
if __name__ == '__main__':
    import sys
    main(sys.argv)
