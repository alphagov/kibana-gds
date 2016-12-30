#!/usr/bin/env groovy

REPOSITORY = 'kibana-gds'
GOVUK_APP_NAME = 'kibana'

node {
  def govuk = load '/var/lib/jenkins/groovy_scripts/govuk_jenkinslib.groovy'

  try {
    stage("Checkout") {
      checkout scm
    }

    stage("Install dependencies") {
      govuk.bundleApp()
    }

    stage("Tests") {
      sh "bundle exec ruby test/test_authwrapper.rb"
    }

    if (env.BRANCH_NAME == 'master') {
      stage("Push release tag") {
        govuk.pushTag(REPOSITORY, env.BRANCH_NAME, 'release_' + env.BUILD_NUMBER)
      }

      stage("Deploy to integration") {
        build job: 'integration-app-deploy',
        parameters: [string(name: GOVUK_APP_NAME, value: 'release_' + env.BUILD_NUMBER)]
      }
    }

  } catch (e) {
    currentBuild.result = "FAILED"
    step([$class: 'Mailer',
          notifyEveryUnstableBuild: true,
          recipients: 'govuk-ci-notifications@digital.cabinet-office.gov.uk',
          sendToIndividuals: true])
    throw e
  }

}
