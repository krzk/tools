Make a persistent SSH reverse proxy tunnel from this machine (let's call
it "local") to remote machine (called "gate").

Expects variables coming from inventory like (see details in vars/tunnel.yml):

    user_tunnel: 'baz'
    tunnels:
      - host_gate: 'my-gate.example.com'
        host_gate_ssh: 'my-gate'
        user_gate: 'foo'
        port_gate: '22'
        port_tunnel_on_gate: 22201
        port_forward: ''
        pubkey_gate: '~/etc/ansible/pubkeys/my-gate.example.com'
      - host_gate: 'another-gate.example.com'
        host_gate_ssh: 'another-gate'
        user_gate: 'someone_else'
        port_gate: '22'
        port_tunnel_on_gate: 22201
        port_forward: ''
        pubkey_gate: '~/etc/ansible/pubkeys/another-gate.example.com'
