local branches = std.extVar('branches');
local branchResourceName(branchName) = 'charts-branch-' + std.strReplace(branchName, '/', '-');

local resources = [{
  name: branchResourceName(branch.name),
  type: 'git',
  source: {
    uri: 'https://github.com/' + branch.repository + '/charts',
    branch: branch.name,
  },
} for branch in branches];

local getSteps = [{
  get: branchResourceName(branch.name),
  trigger: true,
} for branch in branches];

{
  jobs: [
    {
      name: 'maintenance-image',
      plan: [
        {
          get: 'charts-fork-maintenance',
          trigger: true,
        },
        {
          config: {
            image_resource: {
              source: {
                repository: 'concourse/builder',
              },
              type: 'registry-image',
            },
            inputs: [
              {
                name: 'charts-fork-maintenance',
              },
            ],
            outputs: [
              {
                name: 'image',
              },
            ],
            params: {
              CONTEXT: './charts-fork-maintenance',
              REPOSITORY: 'cirocosta/maintenance-image',
            },
            platform: 'linux',
            run: {
              path: 'build',
            },
          },
          privileged: true,
          task: 'build-image',
        },
        {
          get_params: {
            format: 'oci',
          },
          params: {
            image: 'image/image.tar',
          },
          put: 'maintenance-image',
        },
      ],
    },
    {
      name: 'bump-fork',
      plan: [
        {
          aggregate: [
            {
              get: 'charts-upstream',
              trigger: true,
            },
          ],
        },
        {
          inputs: [
            'charts-upstream',
          ],
          params: {
            repository: './charts-upstream',
          },
          put: 'charts-fork',
        },
      ],
    },
    {
      name: 'bump-cirocosta-fork',
      plan: [
        {
          aggregate: [
            {
              get: 'charts-upstream',
              trigger: true,
            },
          ],
        },
        {
          inputs: [
            'charts-upstream',
          ],
          params: {
            repository: './charts-upstream',
          },
          put: 'charts-cirocosta-fork',
        },
      ],
    },
    {
      name: 'update-hosted-helm-repository',
      plan: [
        {
          aggregate: [
            {
              get: 'maintenance-image',
              passed: [
                'update-merged',
              ],
              trigger: true,
            },
            {
              get: 'charts-fork-merged',
              passed: [
                'update-merged',
              ],
              trigger: true,
            },
            {
              get: 'charts-fork-gh-pages',
            },
          ],
        },
        {
          config: {
            inputs: [
              {
                name: 'charts-fork-merged',
              },
              {
                name: 'charts-fork-gh-pages',
                path: 'repository',
              },
            ],
            outputs: [
              {
                name: 'repository',
              },
            ],
            params: {
              CHART_DIR: './charts-fork-merged/stable/concourse',
              DESTINATION_DIR: './repository',
            },
            platform: 'linux',
            run: {
              args: [
                '-c',
                '-e',
                'export GIT_DISCOVERY_ACROSS_FILESYSTEM=1\n\nhelm init --client-only\nhelm repo remove local\nhelm repo update\nhelm package -u -d $DESTINATION_DIR $CHART_DIR\nhelm repo index $DESTINATION_DIR\n\ncd $DESTINATION_DIR\ngit config --global user.name "Ciro S. Costa"\ngit config --global user.email "cscosta@pivotal.io"\ngit add --all\ngit commit -m "[maintenance] bump"\n',
              ],
              path: '/bin/bash',
            },
          },
          image: 'maintenance-image',
          task: 'produce',
        },
        {
          inputs: [
            'repository',
          ],
          params: {
            repository: './repository',
          },
          put: 'charts-fork-gh-pages',
        },
      ],
    },
    {
      name: 'update-merged',
      plan: [
        {
          aggregate: [
            {
              get: 'maintenance-image',
              passed: ['maintenance-image'],
              trigger: true,
            },
            {
              get: 'charts-fork-maintenance',
              passed: [
                'maintenance-image',
              ],
              trigger: true,
            },
            {
              get: 'charts-fork',
              passed: [
                'bump-fork',
              ],
              trigger: true,
            },
          ] + getSteps,
        },
        {
          config: {
            inputs: [
              {
                name: 'charts-fork-maintenance',
                path: '.',
              },
            ],
            outputs: [
              {
                name: 'repository',
                path: '.',
              },
            ],
            platform: 'linux',
            run: {
              args: [
                '-c',
                '-e',
                'git config user.name "Ciro S. Costa"\ngit config user.email "cscosta@pivotal.io"\n\n./update-merged-branch.sh\n\ngit add --all .\ngit commit -m "[maintenance] bumps concourse version"\n',
              ],
              path: '/bin/sh',
            },
          },
          image: 'maintenance-image',
          task: 'run',
        },
        {
          inputs: [
            'repository',
          ],
          params: {
            force: true,
            repository: './repository',
          },
          put: 'charts-fork-merged',
        },
      ],
    },
  ],
  resources: resources + [
    {
      name: 'charts-upstream',
      source: {
        uri: 'https://github.com/helm/charts',
      },
      type: 'git',
    },
    {
      name: 'charts-fork',
      source: {
        branch: 'master',
        uri: 'https://((github-token))@github.com/concourse/charts',
      },
      type: 'git',
    },
    {
      name: 'charts-cirocosta-fork',
      source: {
        branch: 'master',
        uri: 'https://((github-token))@github.com/cirocosta/charts',
      },
      type: 'git',
    },
    {
      name: 'charts-fork-merged',
      source: {
        branch: 'merged',
        uri: 'https://((github-token))@github.com/concourse/charts',
      },
      type: 'git',
    },
    {
      name: 'charts-fork-maintenance',
      source: {
        branch: 'maintenance',
        uri: 'https://((github-token))@github.com/concourse/charts',
      },
      type: 'git',
    },
    {
      name: 'charts-fork-gh-pages',
      source: {
        branch: 'gh-pages',
        uri: 'https://((github-token))@github.com/concourse/charts',
      },
      type: 'git',
    },
    {
      name: 'maintenance-image',
      source: {
        password: '((docker-password))',
        repository: 'cirocosta/charts-maintenance',
        username: '((docker-user))',
      },
      type: 'registry-image',
    },
  ],
}
