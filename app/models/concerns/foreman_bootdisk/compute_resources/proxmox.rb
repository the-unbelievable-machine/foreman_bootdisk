# frozen_string_literal: true

module ForemanBootdisk
  module ComputeResources
    module Proxmox
      def capabilities
        super + [:bootdisk]
      end

      def iso_upload(iso, vm_uuid)
        server = find_vm_by_uuid(vm_uuid)
        config_attributes = {
          'bootdisk' => 'ide2',
          'boot' => 'dcn'
        }
        server.update(config_attributes)
        server.ssh_options = { password: fog_credentials[:pve_password] }
        server.ssh_ip_address = bridges.first.address
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
        config_hash = { ide2: "media=cdrom, file=none" }
        server.update(config_hash)
      end
    end
  end
end
