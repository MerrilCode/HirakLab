#!/usr/bin/env groovy
import groovy.json.JsonOutput
import java.util.Optional
import hudson.tasks.test.AbstractTestResultAction
import hudson.model.Actionable
import hudson.tasks.junit.CaseResult

def speedUp = '--configure-on-demand --daemon --parallel'
def nebulaReleaseScope = (env.GIT_BRANCH == 'origin/master') ? '' : "-Prelease.scope=patch"
def nebulaRelease = "-x prepare -x release snapshot ${nebulaReleaseScope}"
def gradleDefaultSwitches = "${speedUp} ${nebulaRelease}"
def gradleAdditionalTestTargets = "integrationTest"
def gradleAdditionalSwitches = "shadowJar"
def out = ""
def author = "";
def message = "";
def slackNotificationChannel = 'eng-5-build'
def testSummary = ""
def total = 0
def failed = 0
def skipped = 0

def isPublishingBranch = { ->
    return env.GIT_BRANCH == 'origin/master' || env.GIT_BRANCH =~ /release.+/
}

def isResultGoodForPublishing = { ->
    return currentBuild.result == null
}

def notifySlack(text, channel, attachments) {
   def slackURL = "https://hooks.slack.com/services/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"
   def jenkinsIcon = "https://wiki.jenkins-ci.org/download/attachments/2916393/logo.png"

   def payload = JsonOutput.toJson([text: text,
       channel: channel,
       username: "Jenkinsfile test",
       icon_url: jenkinsIcon,
       attachments: attachments
   ])

   sh "curl -X POST --data-urlencode \'payload=${payload}\' ${slackURL}"
}



def getGitAuthor = {
    def commit = sh(returnStdout: true, script: 'git rev-parse HEAD')
    author = sh(returnStdout: true, script: "git --no-pager show -s --format='%an' ${commit}").trim()
}



def getLastCommitMessage = {
    message = sh(returnStdout: true, script: 'git log -1 --pretty=%B').trim()
}


def populateGlobalVariables = {
    getLastCommitMessage()
    getGitAuthor()
}


node('ALMS') {
    try {
        stage('Checkout') {
            checkout scm
        }

        stage("Build"){

            out = sh script: 'rspec spec', returnStdout: true


            populateGlobalVariables()
            def buildColor = currentBuild.result == null ? "good" : "warning"
            def buildStatus = currentBuild.result == null ? "Success" : currentBuild.result
            def jobName = "${env.JOB_NAME}"
            jobName = jobName.getAt(0..(jobName.indexOf('/') - 1))
            notifySlack("", slackNotificationChannel, [
                [

                    color: "${buildColor}",
                    author_name: "${author}",
                    text: "${buildStatus}\n${author}",
                    fields: [
                        [
                            title: "Branch",
                            value: "${env.BRANCH_NAME}",
                            short: true
                        ],
                        [
                            title: "Test Results",
                            value: """${out}""",
                            short: true
                        ],
                        [
                            title: "Last Commit",
                            value: "${message}",
                            short: false
                        ]
                    ]
                ]
            ])
            }

    } catch (hudson.AbortException ae) {

    } catch (e) {
        def buildStatus = "Failed"
        if (isPublishingBranch()) {
            buildStatus = "MasterFailed"
        }
        notifySlack("", slackNotificationChannel, [
            [

                color: "danger",
                author_name: "${author}",
                text: "${buildStatus}",
                fields: [
                    [
                        title: "Branch",
                        value: "${env.BRANCH_NAME}",
                        short: true
                    ],
                    [
                        title: "Test Results",
                        value: "${out}",
                        short: true
                    ],
                    [
                        title: "Last Commit",
                        value: "${message}",
                        short: false
                    ],
                    [
                        title: "Error",
                        value: "${e}",
                        short: false
                    ]
                ]
            ]
        ])
        throw e
    }
  }
