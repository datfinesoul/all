#!/usr/bin/env bash
OWNER="${1:-{owner}}"
REPO="${2:-{repo}}"

gh api graphql -F owner="${OWNER}" -F repo="${REPO}" -f query='
query ($owner:String!, $repo:String!) {
  repository (owner:$owner,name:$repo) {
    collaborators {
      edges {
        permission
        node {
          login
          name
        }
      }
    }
  }
}
' | jq -r '.data.repository.collaborators.edges[] | select(.permission=="ADMIN") | .node | [.name] | @tsv' \
  | sort
