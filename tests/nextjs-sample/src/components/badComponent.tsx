/**
 * BAD: camelCase file name (should be BadComponent.tsx)
 * BAD: Default export without named export
 * This file intentionally violates standards for testing
 */

// BAD: No TypeScript interface for props
export default function badComponent(props: any) {
  // BAD: Using 'any' type
  const data: any = props.data;

  // BAD: Inline styles instead of CSS modules/Tailwind
  return (
    <div style={{ padding: '20px', margin: '10px' }}>
      <span>{data.name}</span>
    </div>
  );
}
