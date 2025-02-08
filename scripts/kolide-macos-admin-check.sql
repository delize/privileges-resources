WITH
_admingroup AS (
  select gid from groups
  where groupname = 'admin'
),
_admin_users AS (
  select uid, uuid, username, description
  from _admingroup
  join user_groups using(gid)
  join users using(uid)
),
_filtered AS (
  select JSON_GROUP_ARRAY(JSON_OBJECT('uid', uid, 'username', username, 'description', description)) AS users,
  count(*) AS count
  from _admin_users
  WHERE username not in ('root', 'administrator', 'jamfadmin')
)

select
*,
IIF(count = 0, 'PASS', 'FAIL') AS KOLIDE_CHECK_STATUS
from _filtered;
