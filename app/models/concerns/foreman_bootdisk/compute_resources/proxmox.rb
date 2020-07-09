# frozen_string_literal: true

module ForemanBootdisk
  module ComputeResources
    module Proxmox
      def capabilities
        super + [:bootdisk]
      end

      def interfaces(node_id = default_node_id)
        node = network_client.nodes.get node_id
        node ||= network_client.nodes.first
        interfaces = node.networks.all(type: 'eth')
        interfaces.sort_by(&:iface)
      end

      def iso_upload(iso, vm_uuid)
        server = find_vm_by_uuid(vm_uuid)
        config_attributes = {
          'bootdisk' => 'scsi0',
          'boot' => 'cnd'
        }
        server.update(config_attributes)
        server.ssh_options = { auth_methods: ['publickey'], keys: ['/home/foreman/.ssh/id_rsa'] }
        #server.ssh_ip_address = bridges.first.address
        server.ssh_ip_address = interfaces.first.address
        server.username = 'ansible'
        server.private_key_path = '/home/foreman/.ssh/id_rsa'
        server.scp_upload(iso, '/var/lib/vz/template/iso/')
        server.reload
        storage = storages(server.node_id, 'iso')[0]
        storage.volumes.any? { |v| v.volid.include? File.basename(iso) }
      end

      def iso_attach(iso, vm_uuid)
        server = find_vm_by_uuid(vm_uuid)
        storage = storages(server.node_id, 'iso')[0]
        volume = storage.volumes.detect { |v| v.volid.include? File.basename(iso) }
        config_hash = { ide2: "#{volume.volid},media=cdrom" }
        server.update(config_hash)
      end

      def iso_detach(vm_uuid)
        server = find_vm_by_uuid(vm_uuid)
        config_hash = { ide2: "none,media=cdrom" }
        server.update(config_hash)
      end
    end
  end
end
