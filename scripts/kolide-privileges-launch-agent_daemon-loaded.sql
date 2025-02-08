WITH sha_checks AS (
  SELECT 
    'corp.sap.privileges' AS service_name,
    CASE 
      WHEN (SELECT sha256 FROM hash WHERE path = '/Library/LaunchAgents/corp.sap.privileges.agent.plist') = '6594b238231b47555b5a0fb5b0372d069c2762b28fc654a8c81f1bb70509530b' 
           THEN 'PASS' ELSE 'FAIL' 
    END AS agent_hash_status,
    CASE 
      WHEN (SELECT sha256 FROM hash WHERE path = '/Library/LaunchDaemons/corp.sap.privileges.daemon.plist') = '7118621fe9b6e6c32949dd8c8b0dda04a6aaf1389f8c4894a0e3b03ae77505ff' 
           THEN 'PASS' ELSE 'FAIL' 
    END AS daemon_hash_status
),
file_checks AS (
  SELECT 
    'corp.sap.privileges' AS service_name,
    CASE
      WHEN EXISTS (SELECT 1 FROM launchd WHERE label = 'corp.sap.privileges.agent') THEN 'YES'
      ELSE 'NO'
    END AS found_agent_in_launchd,
    CASE
      WHEN EXISTS (SELECT 1 FROM launchd WHERE label = 'corp.sap.privileges.daemon') THEN 'YES'
      ELSE 'NO'
    END AS found_daemon_in_launchd,
    CASE
      WHEN EXISTS (SELECT 1 FROM file WHERE path = '/Library/LaunchAgents/corp.sap.privileges.agent.plist') THEN 'YES'
      ELSE 'NO'
    END AS found_agent_plist,
    CASE
      WHEN EXISTS (SELECT 1 FROM file WHERE path = '/Library/LaunchDaemons/corp.sap.privileges.daemon.plist') THEN 'YES'
      ELSE 'NO'
    END AS found_daemon_plist
)
SELECT 
  sha_checks.service_name,
  agent_hash_status,
  daemon_hash_status,
  found_agent_in_launchd,
  found_daemon_in_launchd,
  found_agent_plist,
  found_daemon_plist,
  CASE
    WHEN agent_hash_status = 'PASS' AND daemon_hash_status = 'PASS'
      AND found_agent_plist = 'YES' AND found_daemon_plist = 'YES'
      AND found_agent_in_launchd = 'YES' AND found_daemon_in_launchd = 'YES'
    THEN 'PASS'
    ELSE 'FAIL'
  END AS KOLIDE_CHECK_STATUS
FROM sha_checks
JOIN file_checks ON sha_checks.service_name = file_checks.service_name;
