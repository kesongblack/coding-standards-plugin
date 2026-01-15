/**
 * GOOD: App Router page component
 */

import { UserCard } from '@/components/UserCard';

export default function HomePage() {
  return (
    <main>
      <h1>Welcome</h1>
      <UserCard name="John Doe" email="john@example.com" />
    </main>
  );
}
