// Creates the admin user on first boot and lets anonymous users read job pages (local VM only).
import jenkins.model.Jenkins
import hudson.security.HudsonPrivateSecurityRealm
import hudson.security.FullControlOnceLoggedInAuthorizationStrategy

def j = Jenkins.get()
if (!(j.securityRealm instanceof HudsonPrivateSecurityRealm)) {
    def realm = new HudsonPrivateSecurityRealm(false)
    realm.createAccount('samir', new File('/var/lib/jenkins/admin-password').text.trim())
    j.securityRealm = realm
    def auth = new FullControlOnceLoggedInAuthorizationStrategy()
    auth.allowAnonymousRead = true
    j.authorizationStrategy = auth
    j.save()
}
