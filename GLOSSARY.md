# Gitito

Private git repository hosting: users register SSH keys, create repositories, and share them with other users.

## Language

**Repository**:
A git repository hosted on the server, belonging to exactly one Owner.
_Avoid_: Repo, project

**Owner**:
The user who created a Repository. Only the Owner can delete it or decide who its Collaborators are.
_Avoid_: Admin, creator

**Collaborator**:
A user, other than the Owner, whom the Owner has given access to a Repository. A Collaborator cannot add or remove Collaborators, including themselves.
_Avoid_: Member, contributor, collaborative relation
