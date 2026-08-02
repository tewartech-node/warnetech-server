# Local Forwarding Feature Documentation

**Version:** 1.0.0  
**Created:** 2026-08-02  
**Status:** Initial Implementation

## Overview

The Local Forwarding feature enables secure tunneling of traffic from a local port on the current machine to a remote server through the warnetech-server infrastructure. This is essential for development workflows that need to access internal services, databases, and APIs that are not directly accessible from the internet.

## Use Cases

1. **Database Access** - Forward local port 3306 to an internal MySQL/MariaDB server
2. **Service Tunneling** - Access internal microservices during development
3. **API Testing** - Test against staging/production APIs without exposing them publicly
4. **SSH Access** - Secure access to internal servers
5. **Multi-Hop Tunneling** - Chain multiple hops for deep network access

## Architecture

### Components

```
┌─────────────────────────────────────────────────────────┐
│ Client Application                                      │
│ (connects to localhost:3306)                            │
└────────────────────┬────────────────────────────────────┘
                     │
         ┌───────────┴───────────┐
         │                       │
┌────────▼──────────────────┐   │
│  Local Port Listener      │   │
│  (127.0.0.1:3306)         │   │
└────────┬──────────────────┘   │
         │                       │
         │  Forward to           │
         │                       │
    ┌────▼───────────────────────────┐
    │ Warnetech Server               │
    │ ┌─────────────────────────────┤
    │ │ Forwarding Session Manager  │
    │ └─────────────────────────────┤
    │ ┌─────────────────────────────┤
    │ │ Tunnel Handler (SSH/HTTPS)  │
    │ └─────────────────────────────┘
    └────┬───────────────────────────┘
         │
         │  Tunnel to
         │
    ┌────▼──────────────────────────┐
    │ Remote Server                  │
    │ (db-staging.internal:3306)     │
    └────────────────────────────────┘
```

### Database Schema

#### `local_forwarding_configs`
Stores the configuration for each forwarding tunnel.

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER | Primary key |
| config_name | TEXT | Unique configuration name |
| local_port | INTEGER | Port on local machine (1024-65535) |
| bind_address | TEXT | Bind address (default: 127.0.0.1) |
| remote_host | TEXT | Remote hostname/IP |
| remote_port | INTEGER | Remote port |
| tunnel_type | TEXT | Type of tunnel (ssh, https, cloudflare-tunnel) |
| status | TEXT | Current status (inactive, active, error) |
| created_by | TEXT | Username of creator |
| created_at | TEXT | Creation timestamp |
| updated_at | TEXT | Last update timestamp |

#### `forwarding_sessions`
Tracks active forwarding sessions.

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER | Primary key |
| config_id | INTEGER | Reference to config |
| session_id | TEXT | Unique session identifier |
| tunnel_host | TEXT | Where tunnel is established |
| tunnel_port | INTEGER | Tunnel listening port |
| credentials_ref | TEXT | Reference to stored credentials |
| status | TEXT | Session status (establishing, active, closing, closed, error) |
| established_at | TEXT | When tunnel was established |
| closed_at | TEXT | When tunnel was closed |
| created_at | TEXT | Session creation time |
| updated_at | TEXT | Last update time |

#### `forwarding_audit_log`
Audit trail for all forwarding activities.

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER | Primary key |
| config_id | INTEGER | Config involved |
| session_id | INTEGER | Session involved |
| event_type | TEXT | Event type (config_created, session_started, etc) |
| details | TEXT | Additional details/errors |
| timestamp | TEXT | Event time |
| user | TEXT | User who triggered event |

#### `forwarding_metrics`
Performance metrics for active sessions.

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER | Primary key |
| session_id | INTEGER | Session reference |
| bytes_sent | INTEGER | Total bytes sent |
| bytes_received | INTEGER | Total bytes received |
| active_connections | INTEGER | Current active connections |
| latency_ms | INTEGER | Tunnel latency |
| last_activity_at | TEXT | Last activity timestamp |
| recorded_at | TEXT | Metrics recording time |

## API Endpoints

### Create Configuration
```
POST /api/forwarding
Content-Type: application/json

{
  "config_name": "staging-database",
  "local_port": 3306,
  "bind_address": "127.0.0.1",
  "remote_host": "db-staging.internal.aws.example.com",
  "remote_port": 3306,
  "tunnel_type": "ssh"
}

Response 201:
{
  "id": 1,
  "config_name": "staging-database",
  "local_port": 3306,
  "bind_address": "127.0.0.1",
  "remote_host": "db-staging.internal.aws.example.com",
  "remote_port": 3306,
  "tunnel_type": "ssh",
  "status": "inactive",
  "created_by": "user@example.com",
  "created_at": "2026-08-02T14:30:00Z",
  "updated_at": "2026-08-02T14:30:00Z"
}
```

### List Configurations
```
GET /api/forwarding

Response 200:
[
  {
    "id": 1,
    "config_name": "staging-database",
    "local_port": 3306,
    "bind_address": "127.0.0.1",
    "remote_host": "db-staging.internal.aws.example.com",
    "remote_port": 3306,
    "tunnel_type": "ssh",
    "status": "inactive",
    ...
  }
]
```

### Get Configuration
```
GET /api/forwarding/:id

Response 200:
{
  "id": 1,
  "config_name": "staging-database",
  ...
}
```

### Update Configuration
```
PUT /api/forwarding/:id
Content-Type: application/json

{
  "status": "active",
  "bind_address": "0.0.0.0"
}

Response 200: Updated config object
```

### Delete Configuration
```
DELETE /api/forwarding/:id

Response 200:
{
  "success": true,
  "message": "Configuration deleted"
}
```

### Start Forwarding Session
```
POST /api/forwarding/:id/start

Response 201:
{
  "id": 1,
  "config_id": 1,
  "session_id": "sess_abc123def456",
  "tunnel_host": "localhost",
  "tunnel_port": 3306,
  "status": "establishing",
  "created_at": "2026-08-02T14:30:30Z"
}
```

### Stop Forwarding Session
```
POST /api/forwarding/:id/stop

Response 200:
{
  "success": true
}
```

### Get Session Metrics
```
GET /api/forwarding/:id/metrics

Response 200:
{
  "id": 1,
  "session_id": 1,
  "bytes_sent": 1024000,
  "bytes_received": 2048000,
  "active_connections": 3,
  "latency_ms": 45,
  "last_activity_at": "2026-08-02T14:35:12Z",
  "recorded_at": "2026-08-02T14:35:15Z"
}
```

### Get Audit Log
```
GET /api/forwarding/:id/audit

Response 200:
[
  {
    "id": 1,
    "config_id": 1,
    "event_type": "config_created",
    "details": "Configuration created by user",
    "timestamp": "2026-08-02T14:30:00Z",
    "user": "user@example.com"
  },
  {
    "id": 2,
    "config_id": 1,
    "session_id": 1,
    "event_type": "session_started",
    "details": "Tunnel established successfully",
    "timestamp": "2026-08-02T14:30:30Z",
    "user": "user@example.com"
  }
]
```

## Status Transitions

### Configuration Status
```
inactive ──(activate)──> active
          ──(error)──>    error
active   ──(deactivate)-> inactive
         ──(error)──>     error
error    ──(retry)──>     active
         ──(deactivate)-> inactive
```

### Session Status
```
establishing ──(success)──> active
             ──(error)──>    error
active       ──(user stop)-> closing
             ──(error)──>    error
closing      ──(complete)--> closed
error        ──(retry)──>    establishing
```

## Security Considerations

1. **Port Binding**: By default, ports are bound to 127.0.0.1 (loopback) for local access only
2. **Authentication**: Credentials for remote access are stored encrypted in a separate vault
3. **Audit Logging**: All forwarding activities are logged for compliance and debugging
4. **Rate Limiting**: Implemented at the tunnel level to prevent abuse
5. **Encryption**: All tunnels use encrypted protocols (SSH, HTTPS, or Cloudflare Tunnel)
6. **Access Control**: Forwarding configs are tied to creating user for access control

## Error Handling

### Common Errors

| Error | Cause | Resolution |
|-------|-------|-----------|
| Port already in use | Local port is occupied | Use a different port or stop conflicting service |
| Connection refused | Remote host unreachable | Verify remote host and credentials |
| Authentication failed | Invalid credentials | Check stored credentials in vault |
| Tunnel timeout | Network issues | Check network connectivity, retry |
| Permission denied | User lacks access | Ensure user is authorized for this config |

## Implementation Notes

### Tunnel Types

#### SSH
- **Protocol**: SSH with port forwarding
- **Encryption**: Built-in SSH encryption
- **Best for**: Server-to-server tunneling
- **Auth**: SSH keys or password

#### HTTPS
- **Protocol**: HTTPS with custom headers
- **Encryption**: TLS/SSL
- **Best for**: HTTP/HTTPS services
- **Auth**: API keys or certificates

#### Cloudflare Tunnel
- **Protocol**: Cloudflare's proprietary tunnel
- **Encryption**: End-to-end encryption
- **Best for**: Bypassing firewalls and NAT
- **Auth**: Tunnel token

### Metrics Collection

Metrics are collected at configurable intervals (default: 30 seconds) and include:
- Bytes sent/received
- Active connection count
- Tunnel latency
- Last activity timestamp

Older metrics are automatically cleaned up after 7 days (configurable).

## Migration Steps

To add local forwarding to an existing warnetech-server instance:

1. Run the migration:
   ```sql
   sqlite3 warnetech-server-data.db < schema/002_local_forwarding.sql
   ```

2. Verify tables exist:
   ```sql
   SELECT name FROM sqlite_master WHERE type='table' AND name LIKE 'forwarding%';
   ```

3. Deploy updated API handlers
4. Enable forwarding feature in configuration
5. Test with a sample configuration

## Future Enhancements

- [ ] Web UI for configuration management
- [ ] Mobile app support
- [ ] Advanced authentication methods (2FA, certificate pinning)
- [ ] Geographic load balancing
- [ ] Automatic failover to backup hosts
- [ ] VPN integration
- [ ] Custom tunnel protocols
- [ ] Performance optimization with connection pooling
