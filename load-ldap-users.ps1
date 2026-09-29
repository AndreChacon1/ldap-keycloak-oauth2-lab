$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    $ready = $false
    for ($attempt = 0; $attempt -lt 60; $attempt++) {
        docker exec openldap ldapsearch -x -H ldap://localhost:389 -D 'cn=admin,dc=example,dc=com' -w adminpassword -b 'dc=example,dc=com' -s base 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) { $ready = $true; break }
        Start-Sleep -Seconds 2
    }
    if (-not $ready) { throw 'LDAP no estuvo disponible dentro de 120 segundos.' }
    docker cp ldap/users.ldif openldap:/tmp/users.ldif
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo copiar users.ldif.' }
    docker exec openldap ldapadd -c -x -H ldap://localhost:389 -D 'cn=admin,dc=example,dc=com' -w adminpassword -f /tmp/users.ldif
    foreach ($user in @('alice', 'bob')) {
        $result = docker exec openldap ldapwhoami -x -H ldap://localhost:389 -D "uid=$user,ou=users,dc=example,dc=com" -w "${user}123" 2>&1
        if ($LASTEXITCODE -ne 0) { throw "No se pudo verificar el acceso de $user. $result" }
    }
    Write-Host 'Usuarios LDAP cargados y verificados: alice y bob.'
} finally { Pop-Location }
