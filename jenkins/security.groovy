// Ensures the samir admin account and lets anonymous users read job pages (local VM only).
// Idempotent: the setup wizard may already have created a security realm on first boot.
import jenkins.model.Jenkins
import hudson.model.User
import hudson.security.HudsonPrivateSecurityRealm
import hudson.security.FullControlOnceLoggedInAuthorizationStrategy

def j = Jenkins.get()
def realm = j.securityRealm instanceof HudsonPrivateSecurityRealm ? j.securityRealm : new HudsonPrivateSecurityRealm(false)
if (User.getById('samir', false) == null) {
    realm.createAccount('samir', new File('/var/lib/jenkins/admin-password').text.trim())
}
User.getById('samir', false).setFullName('Samir Kumar Gupta')
j.securityRealm = realm
def auth = new FullControlOnceLoggedInAuthorizationStrategy()
auth.allowAnonymousRead = true
j.authorizationStrategy = auth
j.save()
