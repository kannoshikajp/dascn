'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { 
  LayoutDashboard, 
  Package, 
  Tags, 
  Briefcase, 
  Users, 
  ShieldCheck, 
  Settings, 
  LogOut,
  Menu,
  X
} from 'lucide-react';
import { Button } from '@/components/ui/button';

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [loading, setLoading] = useState(true);
  const [user, setUser] = useState<any>(null);

  useEffect(() => {
    const token = localStorage.getItem('token');
    
    if (!token) {
      router.push('/login');
      return;
    }

    // Verify token and fetch user
    fetch('http://localhost:8888/api/v1/users/me', {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    })
    .then(res => {
      if (!res.ok) throw new Error('Unauthorized');
      return res.json();
    })
    .then(data => {
      setUser(data);
      setLoading(false);
    })
    .catch(() => {
      localStorage.removeItem('token');
      router.push('/login');
    });
  }, [router]);

  const handleLogout = async () => {
    const token = localStorage.getItem('token');
    try {
      await fetch('http://localhost:8888/api/v1/auth/logout', {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${token}` }
      });
    } catch (e) {
      console.error(e);
    } finally {
      localStorage.removeItem('token');
      router.push('/login');
    }
  };

  const navItems = [
    { title: 'Dashboard', href: '/dashboard', icon: LayoutDashboard },
    { title: 'Products', href: '/dashboard/products', icon: Package },
    { title: 'Categories', href: '/dashboard/categories', icon: Tags },
    { title: 'Brands', href: '/dashboard/brands', icon: Briefcase },
    { title: 'Users', href: '/dashboard/users', icon: Users },
    { title: 'Permissions', href: '/dashboard/permissions', icon: ShieldCheck },
    { title: 'Settings', href: '/dashboard/settings', icon: Settings },
  ];

  if (loading) {
    return <div className="flex min-h-screen items-center justify-center">Loading portal...</div>;
  }

  return (
    <div className="flex h-screen bg-gray-100 overflow-hidden">
      
      {/* Mobile Sidebar Overlay */}
      {sidebarOpen && (
        <div 
          className="fixed inset-0 z-20 bg-black/50 md:hidden" 
          onClick={() => setSidebarOpen(false)} 
        />
      )}

      {/* Sidebar */}
      <aside className={`
        fixed inset-y-0 left-0 z-30 w-64 bg-white border-r transform transition-transform duration-200 ease-in-out md:relative md:translate-x-0
        ${sidebarOpen ? 'translate-x-0' : '-translate-x-full'}
      `}>
        <div className="flex h-16 items-center justify-between px-6 border-b">
          <span className="text-xl font-bold tracking-tight text-blue-600">Joppe Admin</span>
          <button className="md:hidden" onClick={() => setSidebarOpen(false)}>
            <X className="h-5 w-5 text-gray-500" />
          </button>
        </div>

        <div className="py-4 overflow-y-auto h-[calc(100vh-4rem)]">
          <ul className="space-y-1 px-3">
            {navItems.map((item) => {
              const Icon = item.icon;
              const isActive = pathname === item.href || pathname.startsWith(`${item.href}/`) && item.href !== '/dashboard';
              
              return (
                <li key={item.href}>
                  <Link 
                    href={item.href}
                    onClick={() => setSidebarOpen(false)}
                    className={`
                      flex items-center gap-3 rounded-md px-3 py-2 text-sm font-medium transition-colors
                      ${isActive 
                        ? 'bg-blue-50 text-blue-700' 
                        : 'text-gray-700 hover:bg-gray-100 hover:text-gray-900'
                      }
                    `}
                  >
                    <Icon className={`h-4 w-4 ${isActive ? 'text-blue-700' : 'text-gray-400'}`} />
                    {item.title}
                  </Link>
                </li>
              );
            })}
          </ul>

          <div className="absolute bottom-0 w-full border-t bg-white p-4">
            <div className="flex items-center gap-3 mb-4">
              <div className="h-8 w-8 rounded-full bg-blue-100 flex items-center justify-center text-blue-700 font-bold">
                {user?.fullName?.charAt(0) || 'U'}
              </div>
              <div className="overflow-hidden">
                <p className="text-sm font-medium truncate">{user?.fullName}</p>
                <p className="text-xs text-gray-500 truncate">{user?.role}</p>
              </div>
            </div>
            <Button 
              variant="outline" 
              className="w-full justify-start text-red-600 hover:text-red-700 hover:bg-red-50" 
              onClick={handleLogout}
            >
              <LogOut className="mr-2 h-4 w-4" />
              Log out
            </Button>
          </div>
        </div>
      </aside>

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col h-screen overflow-hidden">
        
        {/* Top Header (Mobile specific) */}
        <header className="h-16 border-b bg-white flex items-center px-4 md:hidden">
          <button 
            className="p-2 -ml-2 text-gray-600 hover:bg-gray-100 rounded-md"
            onClick={() => setSidebarOpen(true)}
          >
            <Menu className="h-6 w-6" />
          </button>
          <span className="ml-4 text-lg font-semibold">Joppe Portal</span>
        </header>

        {/* Page Content */}
        <main className="flex-1 overflow-auto bg-gray-50 p-4 md:p-8">
          {children}
        </main>
        
      </div>
    </div>
  );
}
