#!perl
use strict;
use warnings;

use lib 't';
use helper;

my $tmp = workdir;
ok -d "t/repos/pipeline-test", "pipeline-test repo exists" or die;
chdir "t/repos/pipeline-test" or die;

bosh_ruby_cli_ok;

runs_ok "genesis repipe --dry-run --config ci/aws/pipeline" and # {{{
runs_ok "genesis repipe --dry-run --config ci/aws/pipeline >$tmp/pipeline.yml" and
yaml_is get_file("$tmp/pipeline.yml"), <<'EOF', "pipeline generated for aws/pipeline (no smoke-tests, untagged)";
groups:
- jobs:
  - client-aws-1-preprod-pipeline-test
  - client-aws-1-prod-pipeline-test
  - client-aws-1-sandbox-pipeline-test
  - notify-client-aws-1-prod-pipeline-test-changes
  name: aws-1
jobs:
- name: client-aws-1-preprod-pipeline-test
  plan:
  - do:
    - aggregate:
      - get: git
      - get: client-aws-1-preprod-cloud-config
        trigger: true
      - get: client-aws-1-preprod-runtime-config
        trigger: true
      - get: client-aws-1-preprod-changes
        trigger: true
      - get: client-aws-1-preprod-cache
        passed:
        - client-aws-1-sandbox-pipeline-test
        trigger: true
    - config:
        image_resource:
          source:
            repository: starkandwayne/concourse
            tag: latest
          type: docker-image
        inputs:
        - name: git
        - name: client-aws-1-preprod-cache
        outputs:
        - name: out
        params:
          BOSH_CA_CERT: |
            ----- BEGIN CERTIFICATE -----
            cert-goes-here
            ----- END CERTIFICATE -----
          BOSH_CLIENT: pp-admin
          BOSH_CLIENT_SECRET: Ahti2eeth3aewohnee1Phaec
          BOSH_ENVIRONMENT: https://preprod.example.com:25555
          BOSH_NON_INTERACTIVE: true
          CACHE_DIR: client-aws-1-preprod-cache
          CURRENT_ENV: client-aws-1-preprod
          GIT_BRANCH: master
          GIT_PRIVATE_KEY: |
            -----BEGIN RSA PRIVATE KEY-----
            lol. you didn't really think that
            we'd put the key here, in a test,
            did you?!
            -----END RSA PRIVATE KEY-----
          OUT_DIR: out/git
          PREVIOUS_ENV: client-aws-1-sandbox
          VAULT_ADDR: https://127.0.0.1:8200
          VAULT_ROLE_ID: null
          VAULT_SECRET_ID: null
          VAULT_SKIP_VERIFY: null
          WORKING_DIR: git
        platform: linux
        run:
          args:
          - ci-pipeline-deploy
          path: client-aws-1-preprod-cache/.genesis/bin/genesis
      ensure:
        params:
          rebase: true
          repository: out/git
        put: git
      task: bosh-deploy
    - config:
        image_resource:
          source:
            repository: starkandwayne/concourse
            tag: latest
          type: docker-image
        inputs:
        - name: out
        - name: client-aws-1-preprod-cache
        outputs:
        - name: cache-out
        params:
          CURRENT_ENV: client-aws-1-preprod
          GIT_BRANCH: master
          GIT_PRIVATE_KEY: |
            -----BEGIN RSA PRIVATE KEY-----
            lol. you didn't really think that
            we'd put the key here, in a test,
            did you?!
            -----END RSA PRIVATE KEY-----
          OUT_DIR: cache-out/git
          WORKING_DIR: out/git
        platform: linux
        run:
          args:
          - ci-generate-cache
          path: client-aws-1-preprod-cache/.genesis/bin/genesis
      task: generate-cache
    - params:
        rebase: true
        repository: cache-out/git
      put: git
    - params:
        rebase: true
        repository: cache-out/git
      put: client-aws-1-prod-cache
    on_failure:
      aggregate:
      - params:
          channel: '#botspam'
          icon_url: http://cl.ly/image/3e1h0H3H2s0P/concourse-logo.png
          text: 'aws-1: Concourse deployment to client-aws-1-preprod-pipeline-test
            failed'
          username: runwaybot
        put: slack
    on_success:
      aggregate:
      - params:
          channel: '#botspam'
          icon_url: http://cl.ly/image/3e1h0H3H2s0P/concourse-logo.png
          text: 'aws-1: Concourse successfully deployed client-aws-1-preprod-pipeline-test'
          username: runwaybot
        put: slack
  public: true
  serial: true
- name: notify-client-aws-1-prod-pipeline-test-changes
  plan:
  - aggregate:
    - get: client-aws-1-prod-changes
      trigger: true
    - get: client-aws-1-prod-cloud-config
      trigger: true
    - get: client-aws-1-prod-runtime-config
      trigger: true
    - get: client-aws-1-prod-cache
      passed:
      - client-aws-1-preprod-pipeline-test
      trigger: true
  - aggregate:
    - params:
        channel: '#botspam'
        icon_url: http://cl.ly/image/3e1h0H3H2s0P/concourse-logo.png
        text: 'aws-1: Changes are staged to be deployed to client-aws-1-prod-pipeline-test,
          please schedule + run a deploy via Concourse'
        username: runwaybot
      put: slack
  public: true
  serial: true
- name: client-aws-1-prod-pipeline-test
  plan:
  - do:
    - aggregate:
      - get: git
      - get: client-aws-1-prod-changes
        passed:
        - notify-client-aws-1-prod-pipeline-test-changes
        trigger: false
      - get: client-aws-1-prod-cache
        passed:
        - notify-client-aws-1-prod-pipeline-test-changes
        trigger: false
    - config:
        image_resource:
          source:
            repository: starkandwayne/concourse
            tag: latest
          type: docker-image
        inputs:
        - name: git
        - name: client-aws-1-prod-cache
        outputs:
        - name: out
        params:
          BOSH_CA_CERT: |
            ----- BEGIN CERTIFICATE -----
            cert-goes-here
            ----- END CERTIFICATE -----
          BOSH_CLIENT: pr-admin
          BOSH_CLIENT_SECRET: eeheelod3veepaepiepee8ahc3rukaefo6equiezuapohS2u
          BOSH_ENVIRONMENT: https://prod.example.com:25555
          BOSH_NON_INTERACTIVE: true
          CACHE_DIR: client-aws-1-prod-cache
          CURRENT_ENV: client-aws-1-prod
          GIT_BRANCH: master
          GIT_PRIVATE_KEY: |
            -----BEGIN RSA PRIVATE KEY-----
            lol. you didn't really think that
            we'd put the key here, in a test,
            did you?!
            -----END RSA PRIVATE KEY-----
          OUT_DIR: out/git
          PREVIOUS_ENV: client-aws-1-preprod
          VAULT_ADDR: https://127.0.0.1:8200
          VAULT_ROLE_ID: null
          VAULT_SECRET_ID: null
          VAULT_SKIP_VERIFY: null
          WORKING_DIR: git
        platform: linux
        run:
          args:
          - ci-pipeline-deploy
          path: client-aws-1-prod-cache/.genesis/bin/genesis
      ensure:
        params:
          rebase: true
          repository: out/git
        put: git
      task: bosh-deploy
    - config:
        image_resource:
          source:
            repository: starkandwayne/concourse
            tag: latest
          type: docker-image
        inputs:
        - name: out
        - name: client-aws-1-prod-cache
        outputs:
        - name: cache-out
        params:
          CURRENT_ENV: client-aws-1-prod
          GIT_BRANCH: master
          GIT_PRIVATE_KEY: |
            -----BEGIN RSA PRIVATE KEY-----
            lol. you didn't really think that
            we'd put the key here, in a test,
            did you?!
            -----END RSA PRIVATE KEY-----
          OUT_DIR: cache-out/git
          WORKING_DIR: out/git
        platform: linux
        run:
          args:
          - ci-generate-cache
          path: client-aws-1-prod-cache/.genesis/bin/genesis
      task: generate-cache
    - params:
        rebase: true
        repository: cache-out/git
      put: git
    on_failure:
      aggregate:
      - params:
          channel: '#botspam'
          icon_url: http://cl.ly/image/3e1h0H3H2s0P/concourse-logo.png
          text: 'aws-1: Concourse deployment to client-aws-1-prod-pipeline-test failed'
          username: runwaybot
        put: slack
    on_success:
      aggregate:
      - params:
          channel: '#botspam'
          icon_url: http://cl.ly/image/3e1h0H3H2s0P/concourse-logo.png
          text: 'aws-1: Concourse successfully deployed client-aws-1-prod-pipeline-test'
          username: runwaybot
        put: slack
  public: true
  serial: true
- name: client-aws-1-sandbox-pipeline-test
  plan:
  - do:
    - aggregate:
      - get: git
      - get: client-aws-1-sandbox-cloud-config
        trigger: true
      - get: client-aws-1-sandbox-runtime-config
        trigger: true
      - get: client-aws-1-sandbox-changes
        trigger: true
    - config:
        image_resource:
          source:
            repository: starkandwayne/concourse
            tag: latest
          type: docker-image
        inputs:
        - name: git
        outputs:
        - name: out
        params:
          BOSH_CA_CERT: |
            ----- BEGIN CERTIFICATE -----
            cert-goes-here
            ----- END CERTIFICATE -----
          BOSH_CLIENT: sb-admin
          BOSH_CLIENT_SECRET: PaeM2Eip
          BOSH_ENVIRONMENT: https://sandbox.example.com:25555
          BOSH_NON_INTERACTIVE: true
          CACHE_DIR: client-aws-1-sandbox-cache
          CURRENT_ENV: client-aws-1-sandbox
          GIT_BRANCH: master
          GIT_PRIVATE_KEY: |
            -----BEGIN RSA PRIVATE KEY-----
            lol. you didn't really think that
            we'd put the key here, in a test,
            did you?!
            -----END RSA PRIVATE KEY-----
          OUT_DIR: out/git
          PREVIOUS_ENV: null
          VAULT_ADDR: https://127.0.0.1:8200
          VAULT_ROLE_ID: null
          VAULT_SECRET_ID: null
          VAULT_SKIP_VERIFY: null
          WORKING_DIR: git
        platform: linux
        run:
          args:
          - ci-pipeline-deploy
          path: git/.genesis/bin/genesis
      ensure:
        params:
          rebase: true
          repository: out/git
        put: git
      task: bosh-deploy
    - config:
        image_resource:
          source:
            repository: starkandwayne/concourse
            tag: latest
          type: docker-image
        inputs:
        - name: out
        - name: git
        outputs:
        - name: cache-out
        params:
          CURRENT_ENV: client-aws-1-sandbox
          GIT_BRANCH: master
          GIT_PRIVATE_KEY: |
            -----BEGIN RSA PRIVATE KEY-----
            lol. you didn't really think that
            we'd put the key here, in a test,
            did you?!
            -----END RSA PRIVATE KEY-----
          OUT_DIR: cache-out/git
          WORKING_DIR: out/git
        platform: linux
        run:
          args:
          - ci-generate-cache
          path: git/.genesis/bin/genesis
      task: generate-cache
    - params:
        rebase: true
        repository: cache-out/git
      put: git
    - params:
        rebase: true
        repository: cache-out/git
      put: client-aws-1-preprod-cache
    on_failure:
      aggregate:
      - params:
          channel: '#botspam'
          icon_url: http://cl.ly/image/3e1h0H3H2s0P/concourse-logo.png
          text: 'aws-1: Concourse deployment to client-aws-1-sandbox-pipeline-test
            failed'
          username: runwaybot
        put: slack
    on_success:
      aggregate:
      - params:
          channel: '#botspam'
          icon_url: http://cl.ly/image/3e1h0H3H2s0P/concourse-logo.png
          text: 'aws-1: Concourse successfully deployed client-aws-1-sandbox-pipeline-test'
          username: runwaybot
        put: slack
  public: true
  serial: true
resource_types:
- name: script
  source:
    repository: cfcommunity/script-resource
  type: docker-image
- name: email
  source:
    repository: pcfseceng/email-resource
  type: docker-image
- name: slack-notification
  source:
    repository: cfcommunity/slack-notification-resource
  type: docker-image
- name: hipchat-notification
  source:
    repository: cfcommunity/hipchat-notification-resource
  type: docker-image
- name: bosh-config
  source:
    repository: cfcommunity/bosh-config-resource
  type: docker-image
- name: locker
  source:
    repository: cfcommunity/locker-resource
  type: docker-image
resources:
- name: git
  source:
    branch: master
    private_key: |
      -----BEGIN RSA PRIVATE KEY-----
      lol. you didn't really think that
      we'd put the key here, in a test,
      did you?!
      -----END RSA PRIVATE KEY-----
    uri: git@github.com:someco/something-deployments
  type: git
- name: client-aws-1-preprod-changes
  source:
    branch: master
    paths:
    - client-aws-1-preprod.yml
    private_key: |
      -----BEGIN RSA PRIVATE KEY-----
      lol. you didn't really think that
      we'd put the key here, in a test,
      did you?!
      -----END RSA PRIVATE KEY-----
    uri: git@github.com:someco/something-deployments
  type: git
- name: client-aws-1-preprod-cache
  source:
    branch: master
    paths:
    - .genesis/bin/genesis
    - .genesis/kits
    - .genesis/config
    - .genesis/cached/client-aws-1-sandbox/client.yml
    - .genesis/cached/client-aws-1-sandbox/client-aws.yml
    - .genesis/cached/client-aws-1-sandbox/client-aws-1.yml
    private_key: |
      -----BEGIN RSA PRIVATE KEY-----
      lol. you didn't really think that
      we'd put the key here, in a test,
      did you?!
      -----END RSA PRIVATE KEY-----
    uri: git@github.com:someco/something-deployments
  type: git
- name: client-aws-1-preprod-cloud-config
  source:
    ca_cert: |
      ----- BEGIN CERTIFICATE -----
      cert-goes-here
      ----- END CERTIFICATE -----
    client: pp-admin
    client_secret: Ahti2eeth3aewohnee1Phaec
    config: cloud
    target: https://preprod.example.com:25555
  type: bosh-config
- name: client-aws-1-preprod-runtime-config
  source:
    ca_cert: |
      ----- BEGIN CERTIFICATE -----
      cert-goes-here
      ----- END CERTIFICATE -----
    client: pp-admin
    client_secret: Ahti2eeth3aewohnee1Phaec
    config: runtime
    target: https://preprod.example.com:25555
  type: bosh-config
- name: client-aws-1-prod-changes
  source:
    branch: master
    paths:
    - client-aws-1-prod.yml
    private_key: |
      -----BEGIN RSA PRIVATE KEY-----
      lol. you didn't really think that
      we'd put the key here, in a test,
      did you?!
      -----END RSA PRIVATE KEY-----
    uri: git@github.com:someco/something-deployments
  type: git
- name: client-aws-1-prod-cache
  source:
    branch: master
    paths:
    - .genesis/bin/genesis
    - .genesis/kits
    - .genesis/config
    - .genesis/cached/client-aws-1-preprod/client.yml
    - .genesis/cached/client-aws-1-preprod/client-aws.yml
    - .genesis/cached/client-aws-1-preprod/client-aws-1.yml
    private_key: |
      -----BEGIN RSA PRIVATE KEY-----
      lol. you didn't really think that
      we'd put the key here, in a test,
      did you?!
      -----END RSA PRIVATE KEY-----
    uri: git@github.com:someco/something-deployments
  type: git
- name: client-aws-1-prod-cloud-config
  source:
    ca_cert: |
      ----- BEGIN CERTIFICATE -----
      cert-goes-here
      ----- END CERTIFICATE -----
    client: pr-admin
    client_secret: eeheelod3veepaepiepee8ahc3rukaefo6equiezuapohS2u
    config: cloud
    target: https://prod.example.com:25555
  type: bosh-config
- name: client-aws-1-prod-runtime-config
  source:
    ca_cert: |
      ----- BEGIN CERTIFICATE -----
      cert-goes-here
      ----- END CERTIFICATE -----
    client: pr-admin
    client_secret: eeheelod3veepaepiepee8ahc3rukaefo6equiezuapohS2u
    config: runtime
    target: https://prod.example.com:25555
  type: bosh-config
- name: client-aws-1-sandbox-changes
  source:
    branch: master
    paths:
    - .genesis/bin/genesis
    - .genesis/kits
    - .genesis/config
    - client.yml
    - client-aws.yml
    - client-aws-1.yml
    - client-aws-1-sandbox.yml
    private_key: |
      -----BEGIN RSA PRIVATE KEY-----
      lol. you didn't really think that
      we'd put the key here, in a test,
      did you?!
      -----END RSA PRIVATE KEY-----
    uri: git@github.com:someco/something-deployments
  type: git
- name: client-aws-1-sandbox-cloud-config
  source:
    ca_cert: |
      ----- BEGIN CERTIFICATE -----
      cert-goes-here
      ----- END CERTIFICATE -----
    client: sb-admin
    client_secret: PaeM2Eip
    config: cloud
    target: https://sandbox.example.com:25555
  type: bosh-config
- name: client-aws-1-sandbox-runtime-config
  source:
    ca_cert: |
      ----- BEGIN CERTIFICATE -----
      cert-goes-here
      ----- END CERTIFICATE -----
    client: sb-admin
    client_secret: PaeM2Eip
    config: runtime
    target: https://sandbox.example.com:25555
  type: bosh-config
- name: slack
  source:
    url: http://127.0.0.1:1337
  type: slack-notification
EOF
# }}}
runs_ok "genesis repipe --dry-run --config ci/aws/pipeline.tagged" and # {{{
runs_ok "genesis repipe --dry-run --config ci/aws/pipeline.tagged >$tmp/pipeline.yml" and
yaml_is get_file("$tmp/pipeline.yml"), <<'EOF', "pipeline generated for aws/pipeline (no smoke-tests, tagged)";
groups:
- jobs:
  - client-aws-1-preprod-pipeline-test
  - client-aws-1-prod-pipeline-test
  - client-aws-1-sandbox-pipeline-test
  - notify-client-aws-1-prod-pipeline-test-changes
  name: aws-1
jobs:
- name: client-aws-1-preprod-pipeline-test
  plan:
  - do:
    - aggregate:
      - get: git
      - get: client-aws-1-preprod-cloud-config
        trigger: true
      - get: client-aws-1-preprod-runtime-config
        trigger: true
      - get: client-aws-1-preprod-changes
        trigger: true
      - get: client-aws-1-preprod-cache
        passed:
        - client-aws-1-sandbox-pipeline-test
        trigger: true
    - config:
        image_resource:
          source:
            repository: starkandwayne/concourse
            tag: latest
          type: docker-image
        inputs:
        - name: git
        - name: client-aws-1-preprod-cache
        outputs:
        - name: out
        params:
          BOSH_CA_CERT: |
            ----- BEGIN CERTIFICATE -----
            cert-goes-here
            ----- END CERTIFICATE -----
          BOSH_CLIENT: pp-admin
          BOSH_CLIENT_SECRET: Ahti2eeth3aewohnee1Phaec
          BOSH_ENVIRONMENT: https://preprod.example.com:25555
          BOSH_NON_INTERACTIVE: true
          CACHE_DIR: client-aws-1-preprod-cache
          CURRENT_ENV: client-aws-1-preprod
          GIT_BRANCH: master
          GIT_PRIVATE_KEY: |
            -----BEGIN RSA PRIVATE KEY-----
            lol. you didn't really think that
            we'd put the key here, in a test,
            did you?!
            -----END RSA PRIVATE KEY-----
          OUT_DIR: out/git
          PREVIOUS_ENV: client-aws-1-sandbox
          VAULT_ADDR: https://127.0.0.1:8200
          VAULT_ROLE_ID: null
          VAULT_SECRET_ID: null
          VAULT_SKIP_VERIFY: null
          WORKING_DIR: git
        platform: linux
        run:
          args:
          - ci-pipeline-deploy
          path: client-aws-1-preprod-cache/.genesis/bin/genesis
      ensure:
        params:
          rebase: true
          repository: out/git
        put: git
      tags:
      - client-aws-1-preprod
      task: bosh-deploy
    - config:
        image_resource:
          source:
            repository: starkandwayne/concourse
            tag: latest
          type: docker-image
        inputs:
        - name: out
        - name: client-aws-1-preprod-cache
        outputs:
        - name: cache-out
        params:
          CURRENT_ENV: client-aws-1-preprod
          GIT_BRANCH: master
          GIT_PRIVATE_KEY: |
            -----BEGIN RSA PRIVATE KEY-----
            lol. you didn't really think that
            we'd put the key here, in a test,
            did you?!
            -----END RSA PRIVATE KEY-----
          OUT_DIR: cache-out/git
          WORKING_DIR: out/git
        platform: linux
        run:
          args:
          - ci-generate-cache
          path: client-aws-1-preprod-cache/.genesis/bin/genesis
      tags:
      - client-aws-1-preprod
      task: generate-cache
    - params:
        rebase: true
        repository: cache-out/git
      put: git
    - params:
        rebase: true
        repository: cache-out/git
      put: client-aws-1-prod-cache
    on_failure:
      aggregate:
      - params:
          channel: '#botspam'
          icon_url: http://cl.ly/image/3e1h0H3H2s0P/concourse-logo.png
          text: 'aws-1: Concourse deployment to client-aws-1-preprod-pipeline-test
            failed'
          username: runwaybot
        put: slack
    on_success:
      aggregate:
      - params:
          channel: '#botspam'
          icon_url: http://cl.ly/image/3e1h0H3H2s0P/concourse-logo.png
          text: 'aws-1: Concourse successfully deployed client-aws-1-preprod-pipeline-test'
          username: runwaybot
        put: slack
  public: true
  serial: true
- name: notify-client-aws-1-prod-pipeline-test-changes
  plan:
  - aggregate:
    - get: client-aws-1-prod-changes
      trigger: true
    - get: client-aws-1-prod-cloud-config
      trigger: true
    - get: client-aws-1-prod-runtime-config
      trigger: true
    - get: client-aws-1-prod-cache
      passed:
      - client-aws-1-preprod-pipeline-test
      trigger: true
  - aggregate:
    - params:
        channel: '#botspam'
        icon_url: http://cl.ly/image/3e1h0H3H2s0P/concourse-logo.png
        text: 'aws-1: Changes are staged to be deployed to client-aws-1-prod-pipeline-test,
          please schedule + run a deploy via Concourse'
        username: runwaybot
      put: slack
  public: true
  serial: true
- name: client-aws-1-prod-pipeline-test
  plan:
  - do:
    - aggregate:
      - get: git
      - get: client-aws-1-prod-changes
        passed:
        - notify-client-aws-1-prod-pipeline-test-changes
        trigger: false
      - get: client-aws-1-prod-cache
        passed:
        - notify-client-aws-1-prod-pipeline-test-changes
        trigger: false
    - config:
        image_resource:
          source:
            repository: starkandwayne/concourse
            tag: latest
          type: docker-image
        inputs:
        - name: git
        - name: client-aws-1-prod-cache
        outputs:
        - name: out
        params:
          BOSH_CA_CERT: |
            ----- BEGIN CERTIFICATE -----
            cert-goes-here
            ----- END CERTIFICATE -----
          BOSH_CLIENT: pr-admin
          BOSH_CLIENT_SECRET: eeheelod3veepaepiepee8ahc3rukaefo6equiezuapohS2u
          BOSH_ENVIRONMENT: https://prod.example.com:25555
          BOSH_NON_INTERACTIVE: true
          CACHE_DIR: client-aws-1-prod-cache
          CURRENT_ENV: client-aws-1-prod
          GIT_BRANCH: master
          GIT_PRIVATE_KEY: |
            -----BEGIN RSA PRIVATE KEY-----
            lol. you didn't really think that
            we'd put the key here, in a test,
            did you?!
            -----END RSA PRIVATE KEY-----
          OUT_DIR: out/git
          PREVIOUS_ENV: client-aws-1-preprod
          VAULT_ADDR: https://127.0.0.1:8200
          VAULT_ROLE_ID: null
          VAULT_SECRET_ID: null
          VAULT_SKIP_VERIFY: null
          WORKING_DIR: git
        platform: linux
        run:
          args:
          - ci-pipeline-deploy
          path: client-aws-1-prod-cache/.genesis/bin/genesis
      ensure:
        params:
          rebase: true
          repository: out/git
        put: git
      tags:
      - client-aws-1-prod
      task: bosh-deploy
    - config:
        image_resource:
          source:
            repository: starkandwayne/concourse
            tag: latest
          type: docker-image
        inputs:
        - name: out
        - name: client-aws-1-prod-cache
        outputs:
        - name: cache-out
        params:
          CURRENT_ENV: client-aws-1-prod
          GIT_BRANCH: master
          GIT_PRIVATE_KEY: |
            -----BEGIN RSA PRIVATE KEY-----
            lol. you didn't really think that
            we'd put the key here, in a test,
            did you?!
            -----END RSA PRIVATE KEY-----
          OUT_DIR: cache-out/git
          WORKING_DIR: out/git
        platform: linux
        run:
          args:
          - ci-generate-cache
          path: client-aws-1-prod-cache/.genesis/bin/genesis
      tags:
      - client-aws-1-prod
      task: generate-cache
    - params:
        rebase: true
        repository: cache-out/git
      put: git
    on_failure:
      aggregate:
      - params:
          channel: '#botspam'
          icon_url: http://cl.ly/image/3e1h0H3H2s0P/concourse-logo.png
          text: 'aws-1: Concourse deployment to client-aws-1-prod-pipeline-test failed'
          username: runwaybot
        put: slack
    on_success:
      aggregate:
      - params:
          channel: '#botspam'
          icon_url: http://cl.ly/image/3e1h0H3H2s0P/concourse-logo.png
          text: 'aws-1: Concourse successfully deployed client-aws-1-prod-pipeline-test'
          username: runwaybot
        put: slack
  public: true
  serial: true
- name: client-aws-1-sandbox-pipeline-test
  plan:
  - do:
    - aggregate:
      - get: git
      - get: client-aws-1-sandbox-cloud-config
        trigger: true
      - get: client-aws-1-sandbox-runtime-config
        trigger: true
      - get: client-aws-1-sandbox-changes
        trigger: true
    - config:
        image_resource:
          source:
            repository: starkandwayne/concourse
            tag: latest
          type: docker-image
        inputs:
        - name: git
        outputs:
        - name: out
        params:
          BOSH_CA_CERT: |
            ----- BEGIN CERTIFICATE -----
            cert-goes-here
            ----- END CERTIFICATE -----
          BOSH_CLIENT: sb-admin
          BOSH_CLIENT_SECRET: PaeM2Eip
          BOSH_ENVIRONMENT: https://sandbox.example.com:25555
          BOSH_NON_INTERACTIVE: true
          CACHE_DIR: client-aws-1-sandbox-cache
          CURRENT_ENV: client-aws-1-sandbox
          GIT_BRANCH: master
          GIT_PRIVATE_KEY: |
            -----BEGIN RSA PRIVATE KEY-----
            lol. you didn't really think that
            we'd put the key here, in a test,
            did you?!
            -----END RSA PRIVATE KEY-----
          OUT_DIR: out/git
          PREVIOUS_ENV: null
          VAULT_ADDR: https://127.0.0.1:8200
          VAULT_ROLE_ID: null
          VAULT_SECRET_ID: null
          VAULT_SKIP_VERIFY: null
          WORKING_DIR: git
        platform: linux
        run:
          args:
          - ci-pipeline-deploy
          path: git/.genesis/bin/genesis
      ensure:
        params:
          rebase: true
          repository: out/git
        put: git
      tags:
      - client-aws-1-sandbox
      task: bosh-deploy
    - config:
        image_resource:
          source:
            repository: starkandwayne/concourse
            tag: latest
          type: docker-image
        inputs:
        - name: out
        - name: git
        outputs:
        - name: cache-out
        params:
          CURRENT_ENV: client-aws-1-sandbox
          GIT_BRANCH: master
          GIT_PRIVATE_KEY: |
            -----BEGIN RSA PRIVATE KEY-----
            lol. you didn't really think that
            we'd put the key here, in a test,
            did you?!
            -----END RSA PRIVATE KEY-----
          OUT_DIR: cache-out/git
          WORKING_DIR: out/git
        platform: linux
        run:
          args:
          - ci-generate-cache
          path: git/.genesis/bin/genesis
      tags:
      - client-aws-1-sandbox
      task: generate-cache
    - params:
        rebase: true
        repository: cache-out/git
      put: git
    - params:
        rebase: true
        repository: cache-out/git
      put: client-aws-1-preprod-cache
    on_failure:
      aggregate:
      - params:
          channel: '#botspam'
          icon_url: http://cl.ly/image/3e1h0H3H2s0P/concourse-logo.png
          text: 'aws-1: Concourse deployment to client-aws-1-sandbox-pipeline-test
            failed'
          username: runwaybot
        put: slack
    on_success:
      aggregate:
      - params:
          channel: '#botspam'
          icon_url: http://cl.ly/image/3e1h0H3H2s0P/concourse-logo.png
          text: 'aws-1: Concourse successfully deployed client-aws-1-sandbox-pipeline-test'
          username: runwaybot
        put: slack
  public: true
  serial: true
resource_types:
- name: script
  source:
    repository: cfcommunity/script-resource
  type: docker-image
- name: email
  source:
    repository: pcfseceng/email-resource
  type: docker-image
- name: slack-notification
  source:
    repository: cfcommunity/slack-notification-resource
  type: docker-image
- name: hipchat-notification
  source:
    repository: cfcommunity/hipchat-notification-resource
  type: docker-image
- name: bosh-config
  source:
    repository: cfcommunity/bosh-config-resource
  type: docker-image
- name: locker
  source:
    repository: cfcommunity/locker-resource
  type: docker-image
resources:
- name: git
  source:
    branch: master
    private_key: |
      -----BEGIN RSA PRIVATE KEY-----
      lol. you didn't really think that
      we'd put the key here, in a test,
      did you?!
      -----END RSA PRIVATE KEY-----
    uri: git@github.com:someco/something-deployments
  type: git
- name: client-aws-1-preprod-changes
  source:
    branch: master
    paths:
    - client-aws-1-preprod.yml
    private_key: |
      -----BEGIN RSA PRIVATE KEY-----
      lol. you didn't really think that
      we'd put the key here, in a test,
      did you?!
      -----END RSA PRIVATE KEY-----
    uri: git@github.com:someco/something-deployments
  type: git
- name: client-aws-1-preprod-cache
  source:
    branch: master
    paths:
    - .genesis/bin/genesis
    - .genesis/kits
    - .genesis/config
    - .genesis/cached/client-aws-1-sandbox/client.yml
    - .genesis/cached/client-aws-1-sandbox/client-aws.yml
    - .genesis/cached/client-aws-1-sandbox/client-aws-1.yml
    private_key: |
      -----BEGIN RSA PRIVATE KEY-----
      lol. you didn't really think that
      we'd put the key here, in a test,
      did you?!
      -----END RSA PRIVATE KEY-----
    uri: git@github.com:someco/something-deployments
  type: git
- name: client-aws-1-preprod-cloud-config
  source:
    ca_cert: |
      ----- BEGIN CERTIFICATE -----
      cert-goes-here
      ----- END CERTIFICATE -----
    client: pp-admin
    client_secret: Ahti2eeth3aewohnee1Phaec
    config: cloud
    target: https://preprod.example.com:25555
  type: bosh-config
- name: client-aws-1-preprod-runtime-config
  source:
    ca_cert: |
      ----- BEGIN CERTIFICATE -----
      cert-goes-here
      ----- END CERTIFICATE -----
    client: pp-admin
    client_secret: Ahti2eeth3aewohnee1Phaec
    config: runtime
    target: https://preprod.example.com:25555
  type: bosh-config
- name: client-aws-1-prod-changes
  source:
    branch: master
    paths:
    - client-aws-1-prod.yml
    private_key: |
      -----BEGIN RSA PRIVATE KEY-----
      lol. you didn't really think that
      we'd put the key here, in a test,
      did you?!
      -----END RSA PRIVATE KEY-----
    uri: git@github.com:someco/something-deployments
  type: git
- name: client-aws-1-prod-cache
  source:
    branch: master
    paths:
    - .genesis/bin/genesis
    - .genesis/kits
    - .genesis/config
    - .genesis/cached/client-aws-1-preprod/client.yml
    - .genesis/cached/client-aws-1-preprod/client-aws.yml
    - .genesis/cached/client-aws-1-preprod/client-aws-1.yml
    private_key: |
      -----BEGIN RSA PRIVATE KEY-----
      lol. you didn't really think that
      we'd put the key here, in a test,
      did you?!
      -----END RSA PRIVATE KEY-----
    uri: git@github.com:someco/something-deployments
  type: git
- name: client-aws-1-prod-cloud-config
  source:
    ca_cert: |
      ----- BEGIN CERTIFICATE -----
      cert-goes-here
      ----- END CERTIFICATE -----
    client: pr-admin
    client_secret: eeheelod3veepaepiepee8ahc3rukaefo6equiezuapohS2u
    config: cloud
    target: https://prod.example.com:25555
  type: bosh-config
- name: client-aws-1-prod-runtime-config
  source:
    ca_cert: |
      ----- BEGIN CERTIFICATE -----
      cert-goes-here
      ----- END CERTIFICATE -----
    client: pr-admin
    client_secret: eeheelod3veepaepiepee8ahc3rukaefo6equiezuapohS2u
    config: runtime
    target: https://prod.example.com:25555
  type: bosh-config
- name: client-aws-1-sandbox-changes
  source:
    branch: master
    paths:
    - .genesis/bin/genesis
    - .genesis/kits
    - .genesis/config
    - client.yml
    - client-aws.yml
    - client-aws-1.yml
    - client-aws-1-sandbox.yml
    private_key: |
      -----BEGIN RSA PRIVATE KEY-----
      lol. you didn't really think that
      we'd put the key here, in a test,
      did you?!
      -----END RSA PRIVATE KEY-----
    uri: git@github.com:someco/something-deployments
  type: git
- name: client-aws-1-sandbox-cloud-config
  source:
    ca_cert: |
      ----- BEGIN CERTIFICATE -----
      cert-goes-here
      ----- END CERTIFICATE -----
    client: sb-admin
    client_secret: PaeM2Eip
    config: cloud
    target: https://sandbox.example.com:25555
  type: bosh-config
- name: client-aws-1-sandbox-runtime-config
  source:
    ca_cert: |
      ----- BEGIN CERTIFICATE -----
      cert-goes-here
      ----- END CERTIFICATE -----
    client: sb-admin
    client_secret: PaeM2Eip
    config: runtime
    target: https://sandbox.example.com:25555
  type: bosh-config
- name: slack
  source:
    url: http://127.0.0.1:1337
  type: slack-notification
EOF
# }}}
runs_ok "genesis repipe --dry-run --config ci/aws/pipeline.tests" and # {{{
runs_ok "genesis repipe --dry-run --config ci/aws/pipeline.tests >$tmp/pipeline.yml" and
yaml_is get_file("$tmp/pipeline.yml"), <<'EOF', "pipeline generated for aws/pipeline (smoke-tests, untagged)";
groups:
- jobs:
  - preprod-pipeline-test
  - prod-pipeline-test
  - sandbox-pipeline-test
  - notify-prod-pipeline-test-changes
  name: aws-1
jobs:
- name: preprod-pipeline-test
  plan:
  - do:
    - aggregate:
      - get: git
      - get: preprod-cloud-config
        trigger: true
      - get: preprod-runtime-config
        trigger: true
      - get: preprod-changes
        trigger: true
      - get: preprod-cache
        passed:
        - sandbox-pipeline-test
        trigger: true
    - config:
        image_resource:
          source:
            repository: starkandwayne/concourse
            tag: latest
          type: docker-image
        inputs:
        - name: git
        - name: preprod-cache
        outputs:
        - name: out
        params:
          BOSH_CA_CERT: |
            ----- BEGIN CERTIFICATE -----
            cert-goes-here
            ----- END CERTIFICATE -----
          BOSH_CLIENT: pp-admin
          BOSH_CLIENT_SECRET: Ahti2eeth3aewohnee1Phaec
          BOSH_ENVIRONMENT: https://preprod.example.com:25555
          BOSH_NON_INTERACTIVE: true
          CACHE_DIR: preprod-cache
          CURRENT_ENV: client-aws-1-preprod
          DEBUG: 1
          GIT_BRANCH: master
          GIT_PRIVATE_KEY: |
            -----BEGIN RSA PRIVATE KEY-----
            lol. you didn't really think that
            we'd put the key here, in a test,
            did you?!
            -----END RSA PRIVATE KEY-----
          OUT_DIR: out/git
          PREVIOUS_ENV: client-aws-1-sandbox
          VAULT_ADDR: https://127.0.0.1:8200
          VAULT_ROLE_ID: null
          VAULT_SECRET_ID: null
          VAULT_SKIP_VERIFY: null
          WORKING_DIR: git
        platform: linux
        run:
          args:
          - ci-pipeline-deploy
          path: preprod-cache/.genesis/bin/genesis
      ensure:
        params:
          rebase: true
          repository: out/git
        put: git
      task: bosh-deploy
    - config:
        image_resource:
          source:
            repository: starkandwayne/concourse
            tag: latest
          type: docker-image
        inputs:
        - name: out
        - name: preprod-cache
        params:
          BOSH_CA_CERT: |
            ----- BEGIN CERTIFICATE -----
            cert-goes-here
            ----- END CERTIFICATE -----
          BOSH_CLIENT: pp-admin
          BOSH_CLIENT_SECRET: Ahti2eeth3aewohnee1Phaec
          BOSH_ENVIRONMENT: https://preprod.example.com:25555
          CURRENT_ENV: client-aws-1-preprod
          DEBUG: 1
          ERRAND_NAME: a-testing-errand-for-the-ages
        platform: linux
        run:
          args:
          - ci-pipeline-run-errand
          dir: out/git
          path: ../../preprod-cache/.genesis/bin/genesis
      task: a-testing-errand-for-the-ages-errand
    - config:
        image_resource:
          source:
            repository: starkandwayne/concourse
            tag: latest
          type: docker-image
        inputs:
        - name: out
        - name: preprod-cache
        outputs:
        - name: cache-out
        params:
          CURRENT_ENV: client-aws-1-preprod
          DEBUG: 1
          GIT_BRANCH: master
          GIT_PRIVATE_KEY: |
            -----BEGIN RSA PRIVATE KEY-----
            lol. you didn't really think that
            we'd put the key here, in a test,
            did you?!
            -----END RSA PRIVATE KEY-----
          OUT_DIR: cache-out/git
          WORKING_DIR: out/git
        platform: linux
        run:
          args:
          - ci-generate-cache
          path: preprod-cache/.genesis/bin/genesis
      task: generate-cache
    - params:
        rebase: true
        repository: cache-out/git
      put: git
    - params:
        rebase: true
        repository: cache-out/git
      put: prod-cache
    on_failure:
      aggregate:
      - params:
          channel: '#botspam'
          icon_url: http://cl.ly/image/3e1h0H3H2s0P/concourse-logo.png
          text: 'aws-1: Concourse deployment to client-aws-1-preprod-pipeline-test
            failed'
          username: runwaybot
        put: slack
    on_success:
      aggregate:
      - params:
          channel: '#botspam'
          icon_url: http://cl.ly/image/3e1h0H3H2s0P/concourse-logo.png
          text: 'aws-1: Concourse successfully deployed client-aws-1-preprod-pipeline-test'
          username: runwaybot
        put: slack
  public: true
  serial: true
- name: notify-prod-pipeline-test-changes
  plan:
  - aggregate:
    - get: prod-changes
      trigger: true
    - get: prod-cloud-config
      trigger: true
    - get: prod-runtime-config
      trigger: true
    - get: prod-cache
      passed:
      - preprod-pipeline-test
      trigger: true
  - aggregate:
    - params:
        channel: '#botspam'
        icon_url: http://cl.ly/image/3e1h0H3H2s0P/concourse-logo.png
        text: 'aws-1: Changes are staged to be deployed to client-aws-1-prod-pipeline-test,
          please schedule + run a deploy via Concourse'
        username: runwaybot
      put: slack
  public: true
  serial: true
- name: prod-pipeline-test
  plan:
  - do:
    - aggregate:
      - get: git
      - get: prod-changes
        passed:
        - notify-prod-pipeline-test-changes
        trigger: false
      - get: prod-cache
        passed:
        - notify-prod-pipeline-test-changes
        trigger: false
    - config:
        image_resource:
          source:
            repository: starkandwayne/concourse
            tag: latest
          type: docker-image
        inputs:
        - name: git
        - name: prod-cache
        outputs:
        - name: out
        params:
          BOSH_CA_CERT: |
            ----- BEGIN CERTIFICATE -----
            cert-goes-here
            ----- END CERTIFICATE -----
          BOSH_CLIENT: pr-admin
          BOSH_CLIENT_SECRET: eeheelod3veepaepiepee8ahc3rukaefo6equiezuapohS2u
          BOSH_ENVIRONMENT: https://prod.example.com:25555
          BOSH_NON_INTERACTIVE: true
          CACHE_DIR: prod-cache
          CURRENT_ENV: client-aws-1-prod
          DEBUG: 1
          GIT_BRANCH: master
          GIT_PRIVATE_KEY: |
            -----BEGIN RSA PRIVATE KEY-----
            lol. you didn't really think that
            we'd put the key here, in a test,
            did you?!
            -----END RSA PRIVATE KEY-----
          OUT_DIR: out/git
          PREVIOUS_ENV: client-aws-1-preprod
          VAULT_ADDR: https://127.0.0.1:8200
          VAULT_ROLE_ID: null
          VAULT_SECRET_ID: null
          VAULT_SKIP_VERIFY: null
          WORKING_DIR: git
        platform: linux
        run:
          args:
          - ci-pipeline-deploy
          path: prod-cache/.genesis/bin/genesis
      ensure:
        params:
          rebase: true
          repository: out/git
        put: git
      task: bosh-deploy
    - config:
        image_resource:
          source:
            repository: starkandwayne/concourse
            tag: latest
          type: docker-image
        inputs:
        - name: out
        - name: prod-cache
        params:
          BOSH_CA_CERT: |
            ----- BEGIN CERTIFICATE -----
            cert-goes-here
            ----- END CERTIFICATE -----
          BOSH_CLIENT: pr-admin
          BOSH_CLIENT_SECRET: eeheelod3veepaepiepee8ahc3rukaefo6equiezuapohS2u
          BOSH_ENVIRONMENT: https://prod.example.com:25555
          CURRENT_ENV: client-aws-1-prod
          DEBUG: 1
          ERRAND_NAME: a-testing-errand-for-the-ages
        platform: linux
        run:
          args:
          - ci-pipeline-run-errand
          dir: out/git
          path: ../../prod-cache/.genesis/bin/genesis
      task: a-testing-errand-for-the-ages-errand
    - config:
        image_resource:
          source:
            repository: starkandwayne/concourse
            tag: latest
          type: docker-image
        inputs:
        - name: out
        - name: prod-cache
        outputs:
        - name: cache-out
        params:
          CURRENT_ENV: client-aws-1-prod
          DEBUG: 1
          GIT_BRANCH: master
          GIT_PRIVATE_KEY: |
            -----BEGIN RSA PRIVATE KEY-----
            lol. you didn't really think that
            we'd put the key here, in a test,
            did you?!
            -----END RSA PRIVATE KEY-----
          OUT_DIR: cache-out/git
          WORKING_DIR: out/git
        platform: linux
        run:
          args:
          - ci-generate-cache
          path: prod-cache/.genesis/bin/genesis
      task: generate-cache
    - params:
        rebase: true
        repository: cache-out/git
      put: git
    on_failure:
      aggregate:
      - params:
          channel: '#botspam'
          icon_url: http://cl.ly/image/3e1h0H3H2s0P/concourse-logo.png
          text: 'aws-1: Concourse deployment to client-aws-1-prod-pipeline-test failed'
          username: runwaybot
        put: slack
    on_success:
      aggregate:
      - params:
          channel: '#botspam'
          icon_url: http://cl.ly/image/3e1h0H3H2s0P/concourse-logo.png
          text: 'aws-1: Concourse successfully deployed client-aws-1-prod-pipeline-test'
          username: runwaybot
        put: slack
  public: true
  serial: true
- name: sandbox-pipeline-test
  plan:
  - do:
    - aggregate:
      - get: git
      - get: sandbox-cloud-config
        trigger: true
      - get: sandbox-runtime-config
        trigger: true
      - get: sandbox-changes
        trigger: true
    - config:
        image_resource:
          source:
            repository: starkandwayne/concourse
            tag: latest
          type: docker-image
        inputs:
        - name: git
        outputs:
        - name: out
        params:
          BOSH_CA_CERT: |
            ----- BEGIN CERTIFICATE -----
            cert-goes-here
            ----- END CERTIFICATE -----
          BOSH_CLIENT: sb-admin
          BOSH_CLIENT_SECRET: PaeM2Eip
          BOSH_ENVIRONMENT: https://sandbox.example.com:25555
          BOSH_NON_INTERACTIVE: true
          CACHE_DIR: sandbox-cache
          CURRENT_ENV: client-aws-1-sandbox
          DEBUG: 1
          GIT_BRANCH: master
          GIT_PRIVATE_KEY: |
            -----BEGIN RSA PRIVATE KEY-----
            lol. you didn't really think that
            we'd put the key here, in a test,
            did you?!
            -----END RSA PRIVATE KEY-----
          OUT_DIR: out/git
          PREVIOUS_ENV: null
          VAULT_ADDR: https://127.0.0.1:8200
          VAULT_ROLE_ID: null
          VAULT_SECRET_ID: null
          VAULT_SKIP_VERIFY: null
          WORKING_DIR: git
        platform: linux
        run:
          args:
          - ci-pipeline-deploy
          path: git/.genesis/bin/genesis
      ensure:
        params:
          rebase: true
          repository: out/git
        put: git
      task: bosh-deploy
    - config:
        image_resource:
          source:
            repository: starkandwayne/concourse
            tag: latest
          type: docker-image
        inputs:
        - name: out
        - name: git
        params:
          BOSH_CA_CERT: |
            ----- BEGIN CERTIFICATE -----
            cert-goes-here
            ----- END CERTIFICATE -----
          BOSH_CLIENT: sb-admin
          BOSH_CLIENT_SECRET: PaeM2Eip
          BOSH_ENVIRONMENT: https://sandbox.example.com:25555
          CURRENT_ENV: client-aws-1-sandbox
          DEBUG: 1
          ERRAND_NAME: a-testing-errand-for-the-ages
        platform: linux
        run:
          args:
          - ci-pipeline-run-errand
          dir: out/git
          path: ../../git/.genesis/bin/genesis
      task: a-testing-errand-for-the-ages-errand
    - config:
        image_resource:
          source:
            repository: starkandwayne/concourse
            tag: latest
          type: docker-image
        inputs:
        - name: out
        - name: git
        outputs:
        - name: cache-out
        params:
          CURRENT_ENV: client-aws-1-sandbox
          DEBUG: 1
          GIT_BRANCH: master
          GIT_PRIVATE_KEY: |
            -----BEGIN RSA PRIVATE KEY-----
            lol. you didn't really think that
            we'd put the key here, in a test,
            did you?!
            -----END RSA PRIVATE KEY-----
          OUT_DIR: cache-out/git
          WORKING_DIR: out/git
        platform: linux
        run:
          args:
          - ci-generate-cache
          path: git/.genesis/bin/genesis
      task: generate-cache
    - params:
        rebase: true
        repository: cache-out/git
      put: git
    - params:
        rebase: true
        repository: cache-out/git
      put: preprod-cache
    on_failure:
      aggregate:
      - params:
          channel: '#botspam'
          icon_url: http://cl.ly/image/3e1h0H3H2s0P/concourse-logo.png
          text: 'aws-1: Concourse deployment to client-aws-1-sandbox-pipeline-test
            failed'
          username: runwaybot
        put: slack
    on_success:
      aggregate:
      - params:
          channel: '#botspam'
          icon_url: http://cl.ly/image/3e1h0H3H2s0P/concourse-logo.png
          text: 'aws-1: Concourse successfully deployed client-aws-1-sandbox-pipeline-test'
          username: runwaybot
        put: slack
  public: true
  serial: true
resource_types:
- name: script
  source:
    repository: cfcommunity/script-resource
  type: docker-image
- name: email
  source:
    repository: pcfseceng/email-resource
  type: docker-image
- name: slack-notification
  source:
    repository: cfcommunity/slack-notification-resource
  type: docker-image
- name: hipchat-notification
  source:
    repository: cfcommunity/hipchat-notification-resource
  type: docker-image
- name: bosh-config
  source:
    repository: cfcommunity/bosh-config-resource
  type: docker-image
- name: locker
  source:
    repository: cfcommunity/locker-resource
  type: docker-image
resources:
- name: git
  source:
    branch: master
    private_key: |
      -----BEGIN RSA PRIVATE KEY-----
      lol. you didn't really think that
      we'd put the key here, in a test,
      did you?!
      -----END RSA PRIVATE KEY-----
    uri: git@github.com:someco/something-deployments
  type: git
- name: preprod-changes
  source:
    branch: master
    paths:
    - client-aws-1-preprod.yml
    private_key: |
      -----BEGIN RSA PRIVATE KEY-----
      lol. you didn't really think that
      we'd put the key here, in a test,
      did you?!
      -----END RSA PRIVATE KEY-----
    uri: git@github.com:someco/something-deployments
  type: git
- name: preprod-cache
  source:
    branch: master
    paths:
    - .genesis/bin/genesis
    - .genesis/kits
    - .genesis/config
    - .genesis/cached/client-aws-1-sandbox/client.yml
    - .genesis/cached/client-aws-1-sandbox/client-aws.yml
    - .genesis/cached/client-aws-1-sandbox/client-aws-1.yml
    private_key: |
      -----BEGIN RSA PRIVATE KEY-----
      lol. you didn't really think that
      we'd put the key here, in a test,
      did you?!
      -----END RSA PRIVATE KEY-----
    uri: git@github.com:someco/something-deployments
  type: git
- name: preprod-cloud-config
  source:
    ca_cert: |
      ----- BEGIN CERTIFICATE -----
      cert-goes-here
      ----- END CERTIFICATE -----
    client: pp-admin
    client_secret: Ahti2eeth3aewohnee1Phaec
    config: cloud
    target: https://preprod.example.com:25555
  type: bosh-config
- name: preprod-runtime-config
  source:
    ca_cert: |
      ----- BEGIN CERTIFICATE -----
      cert-goes-here
      ----- END CERTIFICATE -----
    client: pp-admin
    client_secret: Ahti2eeth3aewohnee1Phaec
    config: runtime
    target: https://preprod.example.com:25555
  type: bosh-config
- name: prod-changes
  source:
    branch: master
    paths:
    - client-aws-1-prod.yml
    private_key: |
      -----BEGIN RSA PRIVATE KEY-----
      lol. you didn't really think that
      we'd put the key here, in a test,
      did you?!
      -----END RSA PRIVATE KEY-----
    uri: git@github.com:someco/something-deployments
  type: git
- name: prod-cache
  source:
    branch: master
    paths:
    - .genesis/bin/genesis
    - .genesis/kits
    - .genesis/config
    - .genesis/cached/client-aws-1-preprod/client.yml
    - .genesis/cached/client-aws-1-preprod/client-aws.yml
    - .genesis/cached/client-aws-1-preprod/client-aws-1.yml
    private_key: |
      -----BEGIN RSA PRIVATE KEY-----
      lol. you didn't really think that
      we'd put the key here, in a test,
      did you?!
      -----END RSA PRIVATE KEY-----
    uri: git@github.com:someco/something-deployments
  type: git
- name: prod-cloud-config
  source:
    ca_cert: |
      ----- BEGIN CERTIFICATE -----
      cert-goes-here
      ----- END CERTIFICATE -----
    client: pr-admin
    client_secret: eeheelod3veepaepiepee8ahc3rukaefo6equiezuapohS2u
    config: cloud
    target: https://prod.example.com:25555
  type: bosh-config
- name: prod-runtime-config
  source:
    ca_cert: |
      ----- BEGIN CERTIFICATE -----
      cert-goes-here
      ----- END CERTIFICATE -----
    client: pr-admin
    client_secret: eeheelod3veepaepiepee8ahc3rukaefo6equiezuapohS2u
    config: runtime
    target: https://prod.example.com:25555
  type: bosh-config
- name: sandbox-changes
  source:
    branch: master
    paths:
    - .genesis/bin/genesis
    - .genesis/kits
    - .genesis/config
    - client.yml
    - client-aws.yml
    - client-aws-1.yml
    - client-aws-1-sandbox.yml
    private_key: |
      -----BEGIN RSA PRIVATE KEY-----
      lol. you didn't really think that
      we'd put the key here, in a test,
      did you?!
      -----END RSA PRIVATE KEY-----
    uri: git@github.com:someco/something-deployments
  type: git
- name: sandbox-cloud-config
  source:
    ca_cert: |
      ----- BEGIN CERTIFICATE -----
      cert-goes-here
      ----- END CERTIFICATE -----
    client: sb-admin
    client_secret: PaeM2Eip
    config: cloud
    target: https://sandbox.example.com:25555
  type: bosh-config
- name: sandbox-runtime-config
  source:
    ca_cert: |
      ----- BEGIN CERTIFICATE -----
      cert-goes-here
      ----- END CERTIFICATE -----
    client: sb-admin
    client_secret: PaeM2Eip
    config: runtime
    target: https://sandbox.example.com:25555
  type: bosh-config
- name: slack
  source:
    url: http://127.0.0.1:1337
  type: slack-notification
EOF
# }}}
runs_ok "genesis repipe --dry-run --config ci/aws/pipeline.everything" and # {{{
runs_ok "genesis repipe --dry-run --config ci/aws/pipeline.everything >$tmp/pipeline.yml" and
yaml_is get_file("$tmp/pipeline.yml"), <<'EOF', "pipeline generated for aws/pipeline (kitchen sink)";
groups:
- jobs:
  - client-aws-1-preprod-pipeline-test
  - client-aws-1-prod-pipeline-test
  - client-aws-1-sandbox-pipeline-test
  - notify-client-aws-1-prod-pipeline-test-changes
  name: aws-1
jobs:
- name: client-aws-1-preprod-pipeline-test
  plan:
  - do:
    - params:
        key: dont-upgrade-bosh-on-me
        lock_op: lock
        locked_by: client-aws-1-preprod-pipeline-test
      put: client-aws-1-preprod-bosh-lock
    - params:
        key: i-need-to-deploy-myself
        lock_op: lock
        locked_by: client-aws-1-preprod-pipeline-test
      put: client-aws-1-preprod-deployment-lock
    - aggregate:
      - get: git
      - get: client-aws-1-preprod-cloud-config
        trigger: true
      - get: client-aws-1-preprod-runtime-config
        trigger: true
      - get: bosh-lite-stemcell
        params:
          tarball: true
        trigger: true
      - get: client-aws-1-preprod-changes
        trigger: true
      - get: client-aws-1-preprod-cache
        passed:
        - client-aws-1-sandbox-pipeline-test
        trigger: true
    - params:
        key: client-aws-1-preprod-pipeline-test
        lock_op: lock
      put: client-aws-1-preprod-stemcell-lock
    - config:
        image_resource:
          source:
            repository: starkandwayne/concourse
          type: docker-image
        inputs:
        - name: client-aws-1-preprod-cache
        - name: bosh-lite-stemcell
          path: stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent
        outputs:
        - name: out
        params:
          BOSH_CA_CERT: |
            ----- BEGIN CERTIFICATE -----
            cert-goes-here
            ----- END CERTIFICATE -----
          BOSH_CLIENT: pp-admin
          BOSH_CLIENT_SECRET: Ahti2eeth3aewohnee1Phaec
          BOSH_ENVIRONMENT: https://preprod.bosh-lite.com:25555
          BOSH_NON_INTERACTIVE: true
          DEBUG: 1
          STEMCELLS: ../stemcells
        platform: linux
        run:
          args:
          - ci-stemcells
          dir: client-aws-1-preprod-cache
          path: .genesis/bin/genesis
      ensure:
        params:
          key: client-aws-1-preprod-pipeline-test
          lock_op: unlock
        put: client-aws-1-preprod-stemcell-lock
      task: upload-stemcells
    - config:
        image_resource:
          source:
            repository: custom/concourse-image
            tag: rc1
          type: docker-image
        inputs:
        - name: git
        - name: client-aws-1-preprod-cache
        outputs:
        - name: out
        params:
          BOSH_CA_CERT: |
            ----- BEGIN CERTIFICATE -----
            cert-goes-here
            ----- END CERTIFICATE -----
          BOSH_CLIENT: pp-admin
          BOSH_CLIENT_SECRET: Ahti2eeth3aewohnee1Phaec
          BOSH_ENVIRONMENT: https://preprod.bosh-lite.com:25555
          BOSH_NON_INTERACTIVE: true
          CACHE_DIR: client-aws-1-preprod-cache
          CURRENT_ENV: client-aws-1-preprod
          DEBUG: 1
          GIT_BRANCH: master
          GIT_PRIVATE_KEY: |
            -----BEGIN RSA PRIVATE KEY-----
            lol. you didn't really think that
            we'd put the key here, in a test,
            did you?!
            -----END RSA PRIVATE KEY-----
          OUT_DIR: out/git
          PREVIOUS_ENV: client-aws-1-sandbox
          VAULT_ADDR: http://myvault.myorg.com:5999
          VAULT_ROLE_ID: role-uuid-here
          VAULT_SECRET_ID: secret-uuid-here
          VAULT_SKIP_VERIFY: 1
          WORKING_DIR: git
        platform: linux
        run:
          args:
          - ci-pipeline-deploy
          path: client-aws-1-preprod-cache/.genesis/bin/genesis
      ensure:
        params:
          rebase: true
          repository: out/git
        put: git
      tags:
      - client-aws-1-preprod
      task: bosh-deploy
    - config:
        image_resource:
          source:
            repository: custom/concourse-image
            tag: rc1
          type: docker-image
        inputs:
        - name: out
        - name: client-aws-1-preprod-cache
        params:
          BOSH_CA_CERT: |
            ----- BEGIN CERTIFICATE -----
            cert-goes-here
            ----- END CERTIFICATE -----
          BOSH_CLIENT: pp-admin
          BOSH_CLIENT_SECRET: Ahti2eeth3aewohnee1Phaec
          BOSH_ENVIRONMENT: https://preprod.bosh-lite.com:25555
          CURRENT_ENV: client-aws-1-preprod
          DEBUG: 1
          ERRAND_NAME: run-something-good
        platform: linux
        run:
          args:
          - ci-pipeline-run-errand
          dir: out/git
          path: ../../client-aws-1-preprod-cache/.genesis/bin/genesis
      tags:
      - client-aws-1-preprod
      task: run-something-good-errand
    - config:
        image_resource:
          source:
            repository: custom/concourse-image
            tag: rc1
          type: docker-image
        inputs:
        - name: out
        - name: client-aws-1-preprod-cache
        outputs:
        - name: cache-out
        params:
          CURRENT_ENV: client-aws-1-preprod
          DEBUG: 1
          GIT_BRANCH: master
          GIT_PRIVATE_KEY: |
            -----BEGIN RSA PRIVATE KEY-----
            lol. you didn't really think that
            we'd put the key here, in a test,
            did you?!
            -----END RSA PRIVATE KEY-----
          OUT_DIR: cache-out/git
          WORKING_DIR: out/git
        platform: linux
        run:
          args:
          - ci-generate-cache
          path: client-aws-1-preprod-cache/.genesis/bin/genesis
      tags:
      - client-aws-1-preprod
      task: generate-cache
    - params:
        rebase: true
        repository: cache-out/git
      put: git
    - params:
        rebase: true
        repository: cache-out/git
      put: client-aws-1-prod-cache
    ensure:
      do:
      - params:
          key: dont-upgrade-bosh-on-me
          lock_op: unlock
          locked_by: client-aws-1-preprod-pipeline-test
        put: client-aws-1-preprod-bosh-lock
      - params:
          key: i-need-to-deploy-myself
          lock_op: unlock
          locked_by: client-aws-1-preprod-pipeline-test
        put: client-aws-1-preprod-deployment-lock
    on_failure:
      aggregate:
      - params:
          channel: '#botspam'
          icon_url: http://cl.ly/image/3e1h0H3H2s0P/concourse-logo.png
          text: 'aws-1: Concourse deployment to client-aws-1-preprod-pipeline-test
            failed'
          username: runwaybot
        put: slack
      - params:
          color: gray
          from: runwaybot
          message: 'aws-1: Concourse deployment to client-aws-1-preprod-pipeline-test
            failed'
          notify: false
        put: hipchat
    on_success:
      aggregate:
      - params:
          channel: '#botspam'
          icon_url: http://cl.ly/image/3e1h0H3H2s0P/concourse-logo.png
          text: 'aws-1: Concourse successfully deployed client-aws-1-preprod-pipeline-test'
          username: runwaybot
        put: slack
      - params:
          color: gray
          from: runwaybot
          message: 'aws-1: Concourse successfully deployed client-aws-1-preprod-pipeline-test'
          notify: false
        put: hipchat
  public: true
  serial: true
- name: notify-client-aws-1-prod-pipeline-test-changes
  plan:
  - aggregate:
    - get: client-aws-1-prod-changes
      trigger: true
    - get: client-aws-1-prod-cloud-config
      trigger: true
    - get: client-aws-1-prod-runtime-config
      trigger: true
    - get: client-aws-1-prod-cache
      passed:
      - client-aws-1-preprod-pipeline-test
      trigger: true
    - get: bosh-lite-stemcell
      params:
        tarball: true
      trigger: true
  - aggregate:
    - params:
        channel: '#botspam'
        icon_url: http://cl.ly/image/3e1h0H3H2s0P/concourse-logo.png
        text: 'aws-1: Changes are staged to be deployed to client-aws-1-prod-pipeline-test,
          please schedule + run a deploy via Concourse'
        username: runwaybot
      put: slack
    - params:
        color: gray
        from: runwaybot
        message: 'aws-1: Changes are staged to be deployed to client-aws-1-prod-pipeline-test,
          please schedule + run a deploy via Concourse'
        notify: false
      put: hipchat
  public: true
  serial: true
- name: client-aws-1-prod-pipeline-test
  plan:
  - do:
    - params:
        key: dont-upgrade-bosh-on-me
        lock_op: lock
        locked_by: client-aws-1-prod-pipeline-test
      put: client-aws-1-prod-bosh-lock
    - params:
        key: i-need-to-deploy-myself
        lock_op: lock
        locked_by: client-aws-1-prod-pipeline-test
      put: client-aws-1-prod-deployment-lock
    - aggregate:
      - get: git
      - get: bosh-lite-stemcell
        params:
          tarball: true
        trigger: false
      - get: client-aws-1-prod-changes
        passed:
        - notify-client-aws-1-prod-pipeline-test-changes
        trigger: false
      - get: client-aws-1-prod-cache
        passed:
        - notify-client-aws-1-prod-pipeline-test-changes
        trigger: false
    - params:
        key: client-aws-1-prod-pipeline-test
        lock_op: lock
      put: client-aws-1-prod-stemcell-lock
    - config:
        image_resource:
          source:
            repository: starkandwayne/concourse
          type: docker-image
        inputs:
        - name: client-aws-1-prod-cache
        - name: bosh-lite-stemcell
          path: stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent
        outputs:
        - name: out
        params:
          BOSH_CA_CERT: |
            ----- BEGIN CERTIFICATE -----
            cert-goes-here
            ----- END CERTIFICATE -----
          BOSH_CLIENT: pr-admin
          BOSH_CLIENT_SECRET: eeheelod3veepaepiepee8ahc3rukaefo6equiezuapohS2u
          BOSH_ENVIRONMENT: https://prod.bosh-lite.com:25555
          BOSH_NON_INTERACTIVE: true
          DEBUG: 1
          STEMCELLS: ../stemcells
        platform: linux
        run:
          args:
          - ci-stemcells
          dir: client-aws-1-prod-cache
          path: .genesis/bin/genesis
      ensure:
        params:
          key: client-aws-1-prod-pipeline-test
          lock_op: unlock
        put: client-aws-1-prod-stemcell-lock
      task: upload-stemcells
    - config:
        image_resource:
          source:
            repository: custom/concourse-image
            tag: rc1
          type: docker-image
        inputs:
        - name: git
        - name: client-aws-1-prod-cache
        outputs:
        - name: out
        params:
          BOSH_CA_CERT: |
            ----- BEGIN CERTIFICATE -----
            cert-goes-here
            ----- END CERTIFICATE -----
          BOSH_CLIENT: pr-admin
          BOSH_CLIENT_SECRET: eeheelod3veepaepiepee8ahc3rukaefo6equiezuapohS2u
          BOSH_ENVIRONMENT: https://prod.bosh-lite.com:25555
          BOSH_NON_INTERACTIVE: true
          CACHE_DIR: client-aws-1-prod-cache
          CURRENT_ENV: client-aws-1-prod
          DEBUG: 1
          GIT_BRANCH: master
          GIT_PRIVATE_KEY: |
            -----BEGIN RSA PRIVATE KEY-----
            lol. you didn't really think that
            we'd put the key here, in a test,
            did you?!
            -----END RSA PRIVATE KEY-----
          OUT_DIR: out/git
          PREVIOUS_ENV: client-aws-1-preprod
          VAULT_ADDR: http://myvault.myorg.com:5999
          VAULT_ROLE_ID: role-uuid-here
          VAULT_SECRET_ID: secret-uuid-here
          VAULT_SKIP_VERIFY: 1
          WORKING_DIR: git
        platform: linux
        run:
          args:
          - ci-pipeline-deploy
          path: client-aws-1-prod-cache/.genesis/bin/genesis
      ensure:
        params:
          rebase: true
          repository: out/git
        put: git
      tags:
      - client-aws-1-prod
      task: bosh-deploy
    - config:
        image_resource:
          source:
            repository: custom/concourse-image
            tag: rc1
          type: docker-image
        inputs:
        - name: out
        - name: client-aws-1-prod-cache
        params:
          BOSH_CA_CERT: |
            ----- BEGIN CERTIFICATE -----
            cert-goes-here
            ----- END CERTIFICATE -----
          BOSH_CLIENT: pr-admin
          BOSH_CLIENT_SECRET: eeheelod3veepaepiepee8ahc3rukaefo6equiezuapohS2u
          BOSH_ENVIRONMENT: https://prod.bosh-lite.com:25555
          CURRENT_ENV: client-aws-1-prod
          DEBUG: 1
          ERRAND_NAME: run-something-good
        platform: linux
        run:
          args:
          - ci-pipeline-run-errand
          dir: out/git
          path: ../../client-aws-1-prod-cache/.genesis/bin/genesis
      tags:
      - client-aws-1-prod
      task: run-something-good-errand
    - config:
        image_resource:
          source:
            repository: custom/concourse-image
            tag: rc1
          type: docker-image
        inputs:
        - name: out
        - name: client-aws-1-prod-cache
        outputs:
        - name: cache-out
        params:
          CURRENT_ENV: client-aws-1-prod
          DEBUG: 1
          GIT_BRANCH: master
          GIT_PRIVATE_KEY: |
            -----BEGIN RSA PRIVATE KEY-----
            lol. you didn't really think that
            we'd put the key here, in a test,
            did you?!
            -----END RSA PRIVATE KEY-----
          OUT_DIR: cache-out/git
          WORKING_DIR: out/git
        platform: linux
        run:
          args:
          - ci-generate-cache
          path: client-aws-1-prod-cache/.genesis/bin/genesis
      tags:
      - client-aws-1-prod
      task: generate-cache
    - params:
        rebase: true
        repository: cache-out/git
      put: git
    ensure:
      do:
      - params:
          key: dont-upgrade-bosh-on-me
          lock_op: unlock
          locked_by: client-aws-1-prod-pipeline-test
        put: client-aws-1-prod-bosh-lock
      - params:
          key: i-need-to-deploy-myself
          lock_op: unlock
          locked_by: client-aws-1-prod-pipeline-test
        put: client-aws-1-prod-deployment-lock
    on_failure:
      aggregate:
      - params:
          channel: '#botspam'
          icon_url: http://cl.ly/image/3e1h0H3H2s0P/concourse-logo.png
          text: 'aws-1: Concourse deployment to client-aws-1-prod-pipeline-test failed'
          username: runwaybot
        put: slack
      - params:
          color: gray
          from: runwaybot
          message: 'aws-1: Concourse deployment to client-aws-1-prod-pipeline-test
            failed'
          notify: false
        put: hipchat
    on_success:
      aggregate:
      - params:
          channel: '#botspam'
          icon_url: http://cl.ly/image/3e1h0H3H2s0P/concourse-logo.png
          text: 'aws-1: Concourse successfully deployed client-aws-1-prod-pipeline-test'
          username: runwaybot
        put: slack
      - params:
          color: gray
          from: runwaybot
          message: 'aws-1: Concourse successfully deployed client-aws-1-prod-pipeline-test'
          notify: false
        put: hipchat
  public: true
  serial: true
- name: client-aws-1-sandbox-pipeline-test
  plan:
  - do:
    - params:
        key: dont-upgrade-bosh-on-me
        lock_op: lock
        locked_by: client-aws-1-sandbox-pipeline-test
      put: client-aws-1-sandbox-bosh-lock
    - params:
        key: i-need-to-deploy-myself
        lock_op: lock
        locked_by: client-aws-1-sandbox-pipeline-test
      put: client-aws-1-sandbox-deployment-lock
    - aggregate:
      - get: git
      - get: client-aws-1-sandbox-cloud-config
        trigger: true
      - get: client-aws-1-sandbox-runtime-config
        trigger: true
      - get: bosh-lite-stemcell
        params:
          tarball: true
        trigger: true
      - get: client-aws-1-sandbox-changes
        trigger: true
    - params:
        key: client-aws-1-sandbox-pipeline-test
        lock_op: lock
      put: client-aws-1-sandbox-stemcell-lock
    - config:
        image_resource:
          source:
            repository: starkandwayne/concourse
          type: docker-image
        inputs:
        - name: git
        - name: bosh-lite-stemcell
          path: stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent
        outputs:
        - name: out
        params:
          BOSH_CA_CERT: |
            ----- BEGIN CERTIFICATE -----
            cert-goes-here
            ----- END CERTIFICATE -----
          BOSH_CLIENT: sb-admin
          BOSH_CLIENT_SECRET: PaeM2Eip
          BOSH_ENVIRONMENT: https://sandbox.bosh-lite.com:25555
          BOSH_NON_INTERACTIVE: true
          DEBUG: 1
          STEMCELLS: ../stemcells
        platform: linux
        run:
          args:
          - ci-stemcells
          dir: git
          path: .genesis/bin/genesis
      ensure:
        params:
          key: client-aws-1-sandbox-pipeline-test
          lock_op: unlock
        put: client-aws-1-sandbox-stemcell-lock
      task: upload-stemcells
    - config:
        image_resource:
          source:
            repository: custom/concourse-image
            tag: rc1
          type: docker-image
        inputs:
        - name: git
        outputs:
        - name: out
        params:
          BOSH_CA_CERT: |
            ----- BEGIN CERTIFICATE -----
            cert-goes-here
            ----- END CERTIFICATE -----
          BOSH_CLIENT: sb-admin
          BOSH_CLIENT_SECRET: PaeM2Eip
          BOSH_ENVIRONMENT: https://sandbox.bosh-lite.com:25555
          BOSH_NON_INTERACTIVE: true
          CACHE_DIR: client-aws-1-sandbox-cache
          CURRENT_ENV: client-aws-1-sandbox
          DEBUG: 1
          GIT_BRANCH: master
          GIT_PRIVATE_KEY: |
            -----BEGIN RSA PRIVATE KEY-----
            lol. you didn't really think that
            we'd put the key here, in a test,
            did you?!
            -----END RSA PRIVATE KEY-----
          OUT_DIR: out/git
          PREVIOUS_ENV: null
          VAULT_ADDR: http://myvault.myorg.com:5999
          VAULT_ROLE_ID: role-uuid-here
          VAULT_SECRET_ID: secret-uuid-here
          VAULT_SKIP_VERIFY: 1
          WORKING_DIR: git
        platform: linux
        run:
          args:
          - ci-pipeline-deploy
          path: git/.genesis/bin/genesis
      ensure:
        params:
          rebase: true
          repository: out/git
        put: git
      tags:
      - client-aws-1-sandbox
      task: bosh-deploy
    - config:
        image_resource:
          source:
            repository: custom/concourse-image
            tag: rc1
          type: docker-image
        inputs:
        - name: out
        - name: git
        params:
          BOSH_CA_CERT: |
            ----- BEGIN CERTIFICATE -----
            cert-goes-here
            ----- END CERTIFICATE -----
          BOSH_CLIENT: sb-admin
          BOSH_CLIENT_SECRET: PaeM2Eip
          BOSH_ENVIRONMENT: https://sandbox.bosh-lite.com:25555
          CURRENT_ENV: client-aws-1-sandbox
          DEBUG: 1
          ERRAND_NAME: run-something-good
        platform: linux
        run:
          args:
          - ci-pipeline-run-errand
          dir: out/git
          path: ../../git/.genesis/bin/genesis
      tags:
      - client-aws-1-sandbox
      task: run-something-good-errand
    - config:
        image_resource:
          source:
            repository: custom/concourse-image
            tag: rc1
          type: docker-image
        inputs:
        - name: out
        - name: git
        outputs:
        - name: cache-out
        params:
          CURRENT_ENV: client-aws-1-sandbox
          DEBUG: 1
          GIT_BRANCH: master
          GIT_PRIVATE_KEY: |
            -----BEGIN RSA PRIVATE KEY-----
            lol. you didn't really think that
            we'd put the key here, in a test,
            did you?!
            -----END RSA PRIVATE KEY-----
          OUT_DIR: cache-out/git
          WORKING_DIR: out/git
        platform: linux
        run:
          args:
          - ci-generate-cache
          path: git/.genesis/bin/genesis
      tags:
      - client-aws-1-sandbox
      task: generate-cache
    - params:
        rebase: true
        repository: cache-out/git
      put: git
    - params:
        rebase: true
        repository: cache-out/git
      put: client-aws-1-preprod-cache
    ensure:
      do:
      - params:
          key: dont-upgrade-bosh-on-me
          lock_op: unlock
          locked_by: client-aws-1-sandbox-pipeline-test
        put: client-aws-1-sandbox-bosh-lock
      - params:
          key: i-need-to-deploy-myself
          lock_op: unlock
          locked_by: client-aws-1-sandbox-pipeline-test
        put: client-aws-1-sandbox-deployment-lock
    on_failure:
      aggregate:
      - params:
          channel: '#botspam'
          icon_url: http://cl.ly/image/3e1h0H3H2s0P/concourse-logo.png
          text: 'aws-1: Concourse deployment to client-aws-1-sandbox-pipeline-test
            failed'
          username: runwaybot
        put: slack
      - params:
          color: gray
          from: runwaybot
          message: 'aws-1: Concourse deployment to client-aws-1-sandbox-pipeline-test
            failed'
          notify: false
        put: hipchat
    on_success:
      aggregate:
      - params:
          channel: '#botspam'
          icon_url: http://cl.ly/image/3e1h0H3H2s0P/concourse-logo.png
          text: 'aws-1: Concourse successfully deployed client-aws-1-sandbox-pipeline-test'
          username: runwaybot
        put: slack
      - params:
          color: gray
          from: runwaybot
          message: 'aws-1: Concourse successfully deployed client-aws-1-sandbox-pipeline-test'
          notify: false
        put: hipchat
  public: true
  serial: true
resource_types:
- name: script
  source:
    repository: cfcommunity/script-resource
  type: docker-image
- name: email
  source:
    repository: pcfseceng/email-resource
  type: docker-image
- name: slack-notification
  source:
    repository: cfcommunity/slack-notification-resource
  type: docker-image
- name: hipchat-notification
  source:
    repository: cfcommunity/hipchat-notification-resource
  type: docker-image
- name: bosh-config
  source:
    repository: cfcommunity/bosh-config-resource
  type: docker-image
- name: locker
  source:
    repository: cfcommunity/locker-resource
  type: docker-image
resources:
- name: git
  source:
    branch: master
    private_key: |
      -----BEGIN RSA PRIVATE KEY-----
      lol. you didn't really think that
      we'd put the key here, in a test,
      did you?!
      -----END RSA PRIVATE KEY-----
    uri: git@github.com:someco/something-deployments
  type: git
- name: bosh-lite-stemcell
  source:
    name: bosh-warden-boshlite-ubuntu-trusty-go_agent
  type: bosh-io-stemcell
- name: client-aws-1-preprod-changes
  source:
    branch: master
    paths:
    - client-aws-1-preprod.yml
    private_key: |
      -----BEGIN RSA PRIVATE KEY-----
      lol. you didn't really think that
      we'd put the key here, in a test,
      did you?!
      -----END RSA PRIVATE KEY-----
    uri: git@github.com:someco/something-deployments
  type: git
- name: client-aws-1-preprod-cache
  source:
    branch: master
    paths:
    - .genesis/bin/genesis
    - .genesis/kits
    - .genesis/config
    - .genesis/cached/client-aws-1-sandbox/client.yml
    - .genesis/cached/client-aws-1-sandbox/client-aws.yml
    - .genesis/cached/client-aws-1-sandbox/client-aws-1.yml
    private_key: |
      -----BEGIN RSA PRIVATE KEY-----
      lol. you didn't really think that
      we'd put the key here, in a test,
      did you?!
      -----END RSA PRIVATE KEY-----
    uri: git@github.com:someco/something-deployments
  type: git
- name: client-aws-1-preprod-cloud-config
  source:
    ca_cert: |
      ----- BEGIN CERTIFICATE -----
      cert-goes-here
      ----- END CERTIFICATE -----
    client: pp-admin
    client_secret: Ahti2eeth3aewohnee1Phaec
    config: cloud
    target: https://preprod.bosh-lite.com:25555
  type: bosh-config
- name: client-aws-1-preprod-runtime-config
  source:
    ca_cert: |
      ----- BEGIN CERTIFICATE -----
      cert-goes-here
      ----- END CERTIFICATE -----
    client: pp-admin
    client_secret: Ahti2eeth3aewohnee1Phaec
    config: runtime
    target: https://preprod.bosh-lite.com:25555
  type: bosh-config
- name: client-aws-1-preprod-stemcell-lock
  source:
    ca_cert: null
    lock_name: 10.244.0.34:25555-stemcell-lock
    locker_uri: https://127.0.0.1:8910
    password: locker
    skip_ssl_validation: true
    username: locker
  type: locker
- name: client-aws-1-preprod-bosh-lock
  source:
    bosh_lock: https://preprod.bosh-lite.com:25555
    ca_cert: null
    locker_uri: https://127.0.0.1:8910
    password: locker
    skip_ssl_validation: true
    username: locker
  type: locker
- name: client-aws-1-preprod-deployment-lock
  source:
    ca_cert: null
    lock_name: client-aws-1-preprod-pipeline-test
    locker_uri: https://127.0.0.1:8910
    password: locker
    skip_ssl_validation: true
    username: locker
  type: locker
- name: client-aws-1-prod-changes
  source:
    branch: master
    paths:
    - client-aws-1-prod.yml
    private_key: |
      -----BEGIN RSA PRIVATE KEY-----
      lol. you didn't really think that
      we'd put the key here, in a test,
      did you?!
      -----END RSA PRIVATE KEY-----
    uri: git@github.com:someco/something-deployments
  type: git
- name: client-aws-1-prod-cache
  source:
    branch: master
    paths:
    - .genesis/bin/genesis
    - .genesis/kits
    - .genesis/config
    - .genesis/cached/client-aws-1-preprod/client.yml
    - .genesis/cached/client-aws-1-preprod/client-aws.yml
    - .genesis/cached/client-aws-1-preprod/client-aws-1.yml
    private_key: |
      -----BEGIN RSA PRIVATE KEY-----
      lol. you didn't really think that
      we'd put the key here, in a test,
      did you?!
      -----END RSA PRIVATE KEY-----
    uri: git@github.com:someco/something-deployments
  type: git
- name: client-aws-1-prod-cloud-config
  source:
    ca_cert: |
      ----- BEGIN CERTIFICATE -----
      cert-goes-here
      ----- END CERTIFICATE -----
    client: pr-admin
    client_secret: eeheelod3veepaepiepee8ahc3rukaefo6equiezuapohS2u
    config: cloud
    target: https://prod.bosh-lite.com:25555
  type: bosh-config
- name: client-aws-1-prod-runtime-config
  source:
    ca_cert: |
      ----- BEGIN CERTIFICATE -----
      cert-goes-here
      ----- END CERTIFICATE -----
    client: pr-admin
    client_secret: eeheelod3veepaepiepee8ahc3rukaefo6equiezuapohS2u
    config: runtime
    target: https://prod.bosh-lite.com:25555
  type: bosh-config
- name: client-aws-1-prod-stemcell-lock
  source:
    ca_cert: null
    lock_name: 10.244.0.34:25555-stemcell-lock
    locker_uri: https://127.0.0.1:8910
    password: locker
    skip_ssl_validation: true
    username: locker
  type: locker
- name: client-aws-1-prod-bosh-lock
  source:
    bosh_lock: https://prod.bosh-lite.com:25555
    ca_cert: null
    locker_uri: https://127.0.0.1:8910
    password: locker
    skip_ssl_validation: true
    username: locker
  type: locker
- name: client-aws-1-prod-deployment-lock
  source:
    ca_cert: null
    lock_name: client-aws-1-prod-pipeline-test
    locker_uri: https://127.0.0.1:8910
    password: locker
    skip_ssl_validation: true
    username: locker
  type: locker
- name: client-aws-1-sandbox-changes
  source:
    branch: master
    paths:
    - .genesis/bin/genesis
    - .genesis/kits
    - .genesis/config
    - client.yml
    - client-aws.yml
    - client-aws-1.yml
    - client-aws-1-sandbox.yml
    private_key: |
      -----BEGIN RSA PRIVATE KEY-----
      lol. you didn't really think that
      we'd put the key here, in a test,
      did you?!
      -----END RSA PRIVATE KEY-----
    uri: git@github.com:someco/something-deployments
  type: git
- name: client-aws-1-sandbox-cloud-config
  source:
    ca_cert: |
      ----- BEGIN CERTIFICATE -----
      cert-goes-here
      ----- END CERTIFICATE -----
    client: sb-admin
    client_secret: PaeM2Eip
    config: cloud
    target: https://sandbox.bosh-lite.com:25555
  type: bosh-config
- name: client-aws-1-sandbox-runtime-config
  source:
    ca_cert: |
      ----- BEGIN CERTIFICATE -----
      cert-goes-here
      ----- END CERTIFICATE -----
    client: sb-admin
    client_secret: PaeM2Eip
    config: runtime
    target: https://sandbox.bosh-lite.com:25555
  type: bosh-config
- name: client-aws-1-sandbox-stemcell-lock
  source:
    ca_cert: null
    lock_name: 10.244.0.34:25555-stemcell-lock
    locker_uri: https://127.0.0.1:8910
    password: locker
    skip_ssl_validation: true
    username: locker
  type: locker
- name: client-aws-1-sandbox-bosh-lock
  source:
    bosh_lock: https://sandbox.bosh-lite.com:25555
    ca_cert: null
    locker_uri: https://127.0.0.1:8910
    password: locker
    skip_ssl_validation: true
    username: locker
  type: locker
- name: client-aws-1-sandbox-deployment-lock
  source:
    ca_cert: null
    lock_name: client-aws-1-sandbox-pipeline-test
    locker_uri: https://127.0.0.1:8910
    password: locker
    skip_ssl_validation: true
    username: locker
  type: locker
- name: slack
  source:
    url: http://127.0.0.1:1337
  type: slack-notification
- name: hipchat
  source:
    hipchat_server_url: http://api.hipchat.com
    room_id: 1234
    token: abcdefg
  type: hipchat-notification
EOF
# }}}

output_ok "genesis describe --config ci/pipeline.all", <<EOF, "large pipelines are described properly"; # {{{
sandbox-1
  `--> dev-1
        |--> preprod-1
        |     `--> prod-1
        `--> qa-1

sandbox-2
  |--> preprod-2
  |     `--> prod-2
  `--> preprod-3
        |--> prod-3
        |--> prod-4
        `--> prod-5
EOF
 # }}}
output_ok "genesis describe --config ci/aws/pipeline", <<EOF, "small pipelines are described properly"; # {{{
client-aws-1-sandbox
  `--> client-aws-1-preprod
        `--> client-aws-1-prod
EOF
# }}}

done_testing;
