'use client';

import { useEffect, useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Checkbox } from '@/components/ui/checkbox';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Shield, Plus, Trash2, Save, AlertCircle } from 'lucide-react';

interface Permission {
  id: number;
  permissionName: string;
  description: string;
  category: string;
}

interface Role {
  id: number;
  groupName: string; // This is the role name
  description: string;
  isBuiltIn: boolean;
  permissions: Permission[];
}

export default function RolesPage() {
  const [roles, setRoles] = useState<Role[]>([]);
  const [allPermissions, setAllPermissions] = useState<Permission[]>([]);
  const [loading, setLoading] = useState(true);
  
  // Local state for checkboxes: roleId -> Set<permissionId>
  const [rolePerms, setRolePerms] = useState<Record<number, Set<number>>>({});

  // Role Create Modal
  const [isCreateRoleOpen, setIsCreateRoleOpen] = useState(false);
  const [newRoleName, setNewRoleName] = useState('');
  const [newRoleDesc, setNewRoleDesc] = useState('');

  const fetchData = async () => {
    try {
      const token = localStorage.getItem('token');
      const [rolesRes, permsRes] = await Promise.all([
        fetch('http://localhost:8888/api/v1/permission-groups', { headers: { 'Authorization': `Bearer ${token}` } }),
        fetch('http://localhost:8888/api/v1/permissions', { headers: { 'Authorization': `Bearer ${token}` } })
      ]);
      
      const rolesData = await rolesRes.json();
      const permsData = await permsRes.json();
      
      setRoles(rolesData);
      setAllPermissions(permsData);
      
      const initialMap: Record<number, Set<number>> = {};
      rolesData.forEach((role: Role) => {
        initialMap[role.id] = new Set(role.permissions?.map(p => p.id) || []);
      });
      setRolePerms(initialMap);
      
    } catch (err: any) {
      alert(err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const handleToggle = (roleId: number, permId: number) => {
    setRolePerms(prev => {
      const newMap = { ...prev };
      const perms = new Set(newMap[roleId] || []);
      if (perms.has(permId)) perms.delete(permId);
      else perms.add(permId);
      newMap[roleId] = perms;
      return newMap;
    });
  };

  const handleSaveRole = async (roleId: number) => {
    try {
      const token = localStorage.getItem('token');
      const permsArray = Array.from(rolePerms[roleId] || []);

      const res = await fetch(`http://localhost:8888/api/v1/permission-groups/${roleId}/permissions`, {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify(permsArray)
      });
      
      if (!res.ok) throw new Error('Failed to save role permissions');
      alert('Saved successfully!');
      fetchData();
    } catch (err: any) {
      alert(err.message);
    }
  };

  const handleCreateRole = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const token = localStorage.getItem('token');
      await fetch('http://localhost:8888/api/v1/permission-groups', {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ groupName: newRoleName, description: newRoleDesc })
      });
      setNewRoleName(''); setNewRoleDesc(''); setIsCreateRoleOpen(false);
      fetchData();
    } catch (err: any) { alert(err.message); }
  };

  const handleDeleteRole = async (id: number) => {
    if (!confirm('Are you sure you want to delete this role?')) return;
    try {
      const token = localStorage.getItem('token');
      await fetch(`http://localhost:8888/api/v1/permission-groups/${id}`, { method: 'DELETE', headers: { 'Authorization': `Bearer ${token}` } });
      fetchData();
    } catch (err: any) { alert(err.message); }
  };

  // Group permissions by category
  const permissionsByCategory = allPermissions.reduce((acc, perm) => {
    const cat = perm.category || 'Uncategorized';
    if (!acc[cat]) acc[cat] = [];
    acc[cat].push(perm);
    return acc;
  }, {} as Record<string, Permission[]>);

  if (loading) return <div className="py-8 text-center">Loading...</div>;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Roles & Permissions</h1>
          <p className="text-gray-500">Configure what each role is allowed to do.</p>
        </div>
        
        <div className="flex gap-2">
          <Dialog open={isCreateRoleOpen} onOpenChange={setIsCreateRoleOpen}>
            <DialogTrigger render={<Button className="bg-blue-600 hover:bg-blue-700" />}>
              <Plus className="mr-2 h-4 w-4" /> Create Role
            </DialogTrigger>
            <DialogContent>
              <form onSubmit={handleCreateRole}>
                <DialogHeader><DialogTitle>Create Role</DialogTitle></DialogHeader>
                <div className="grid gap-4 py-4">
                  <Input placeholder="Role Name (e.g. MANAGER)" value={newRoleName} onChange={(e) => setNewRoleName(e.target.value)} required />
                  <Input placeholder="Description" value={newRoleDesc} onChange={(e) => setNewRoleDesc(e.target.value)} required />
                </div>
                <DialogFooter><Button type="submit">Create</Button></DialogFooter>
              </form>
            </DialogContent>
          </Dialog>
        </div>
      </div>

      <div className="grid grid-cols-1 gap-6">
        {roles.map((role) => {
          const isSystemAdmin = role.groupName === 'ADMIN';

          return (
            <Card key={role.id} className="overflow-hidden">
              <CardHeader className="bg-gray-50/50 border-b flex flex-row items-center justify-between pb-4">
                <div>
                  <div className="flex items-center gap-2">
                    <CardTitle className="text-lg">{role.groupName}</CardTitle>
                    {role.isBuiltIn && (
                      <span className="inline-flex items-center rounded-full bg-blue-50 px-2 py-0.5 text-[10px] font-medium text-blue-700 ring-1 ring-inset ring-blue-700/10">
                        <Shield className="mr-1 h-3 w-3" /> System
                      </span>
                    )}
                  </div>
                  <CardDescription className="mt-1">{role.description}</CardDescription>
                </div>
                <div className="flex gap-2">
                  <Button variant="outline" size="sm" onClick={() => handleSaveRole(role.id)} className="bg-green-50 text-green-700 hover:bg-green-100 border-green-200">
                    <Save className="mr-2 h-4 w-4" /> Save Roles
                  </Button>
                  {!role.isBuiltIn && (
                    <Button variant="outline" size="sm" className="text-red-600 hover:bg-red-50" onClick={() => handleDeleteRole(role.id)}>
                      <Trash2 className="h-4 w-4" />
                    </Button>
                  )}
                </div>
              </CardHeader>
              <CardContent className="p-6 space-y-8">
                {isSystemAdmin && (
                  <div className="flex items-center gap-2 text-sm text-blue-700 bg-blue-50 p-3 rounded-md">
                    <AlertCircle className="h-4 w-4" />
                    The ADMIN role automatically has access to all permissions. Modifications are disabled.
                  </div>
                )}
                
                {Object.entries(permissionsByCategory).map(([category, perms]) => (
                  <div key={category} className="space-y-3">
                    <h3 className="font-semibold text-sm text-gray-900 border-b pb-1">{category}</h3>
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                      {perms.map(perm => {
                        const isChecked = rolePerms[role.id]?.has(perm.id) || false;
                        const isDisabled = isSystemAdmin;
                        
                        return (
                          <div key={perm.id} className="flex items-start space-x-3 bg-gray-50/50 p-3 rounded-md border border-gray-100">
                            <Checkbox 
                              id={`role-${role.id}-perm-${perm.id}`}
                              checked={isSystemAdmin ? true : isChecked} 
                              disabled={isDisabled}
                              onCheckedChange={() => handleToggle(role.id, perm.id)}
                            />
                            <div className="grid gap-1.5 leading-none">
                              <label
                                htmlFor={`role-${role.id}-perm-${perm.id}`}
                                className="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70 cursor-pointer"
                              >
                                {perm.permissionName}
                              </label>
                              <p className="text-xs text-gray-500">{perm.description}</p>
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  </div>
                ))}
              </CardContent>
            </Card>
          );
        })}
      </div>
    </div>
  );
}
