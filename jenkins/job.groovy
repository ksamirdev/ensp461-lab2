// Creates the ensp461-lab2-cd pipeline job from the Jenkinsfile in the GitHub repository.
import jenkins.model.Jenkins
import org.jenkinsci.plugins.workflow.job.WorkflowJob
import org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition
import hudson.plugins.git.GitSCM
import hudson.plugins.git.BranchSpec
import hudson.triggers.SCMTrigger

def j = Jenkins.get()
if (j.getItem('ensp461-lab2-cd') == null) {
    def scm = new GitSCM(GitSCM.createRepoList('https://github.com/ksamirdev/ensp461-lab2.git', null),
            [new BranchSpec('*/main')], null, null, [])
    def job = j.createProject(WorkflowJob, 'ensp461-lab2-cd')
    job.description = 'Lab 2 CD: test, build, push to lab2-registry, deploy to Minikube'
    job.definition = new CpsScmFlowDefinition(scm, 'Jenkinsfile')
    job.addTrigger(new SCMTrigger('H/2 * * * *'))
    job.save()
}
