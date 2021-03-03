use master

select * from sys.dm_hadr_database_replica_cluster_states


SELECT DISTINCT ag.name as AG_name, 
	rs.replica_server_name,
	rst.role_desc,
	cst.is_failover_ready,
	DB_NAME(drs.database_id) as [DataBase], 
	rs.endpoint_url,
	rs.availability_mode_desc,
	rs.failover_mode_desc,   
	drs.synchronization_state_desc, 
	ag.sequence_number,
	ag.automated_backup_preference_desc,
	gst.synchronization_health_desc,
	drs.last_commit_lsn,
	drs.secondary_lag_seconds,
	drs.is_suspended,
	drs.suspend_reason_desc
FROM sys.dm_hadr_database_replica_states drs
inner join sys.availability_groups ag ON drs.group_id = ag.group_id
inner join sys.availability_replicas rs on rs.replica_id = drs.replica_id and rs.group_id = drs.group_id
inner join sys.dm_hadr_availability_group_states gst on drs.group_id = gst.group_id
inner join sys.dm_hadr_availability_replica_states rst on drs.group_id = rst.group_id and drs.replica_id = rst.replica_id
inner join sys.dm_hadr_database_replica_cluster_states cst on drs.replica_id = cst.replica_id

select * from sys.dm_hadr_database_replica_cluster_states

select * from sys.dm_hadr_availability_group_states

SELECT * FROM sys.availability_replicas


select * from sys.dm_hadr_cluster
select * from sys.dm_hadr_cluster_members
select * from sys.dm_hadr_cluster_networks
select * from sys.dm_hadr_instance_node_map

select * from sys.availability_groups
select * from sys.availability_groups_cluster
select * from sys.dm_hadr_availability_group_states

select * from sys.availability_replicas
select * from sys.dm_hadr_availability_replica_cluster_nodes
select * from sys.dm_hadr_availability_replica_cluster_states
select * from sys.dm_hadr_availability_replica_states
select * from sys.dm_hadr_auto_page_repair
select last_commit_lsn, * from sys.dm_hadr_database_replica_states
select * from sys.dm_hadr_database_replica_cluster_states
select * from sys.availability_group_listener_ip_addresses
select * from sys.availability_group_listeners
select * from sys.dm_tcp_listener_states

SELECT is_failover_ready, b.replica_server_name, b.endpoint_url, b.availability_mode_desc, b.failover_mode_desc, *
FROM sys.dm_hadr_database_replica_cluster_states a
inner join sys.availability_replicas b on a.replica_id = b.replica_id
 

select * from sys.availability_replicas

SELECT start_time, 
    completion_time
    is_source,
    current_state,
    failure_state,
    failure_state_desc
FROM sys.dm_hadr_automatic_seeding

SELECT * FROM sys.TCP_endpoints  


SELECT  member_name, member_state_desc, number_of_quorum_votes  , *
 FROM   sys.dm_hadr_cluster_members;  
