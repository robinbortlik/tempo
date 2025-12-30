## Tailwind CSS Standards

### Utility-First Approach
- Use Tailwind utility classes directly in JSX
- Avoid custom CSS unless absolutely necessary
- Use the `cn()` utility for conditional classes

```tsx
// Good - utility classes
<div className="p-8 bg-white rounded-xl border border-stone-200">
  <h1 className="text-2xl font-semibold text-stone-900">Title</h1>
</div>

// Good - conditional classes with cn()
import { cn } from "@/lib/utils";

<button className={cn(
  "px-4 py-2 rounded-lg font-medium",
  isActive && "bg-stone-900 text-white",
  !isActive && "bg-white border border-stone-200"
)}>
```

### Color Palette
- Primary: `stone-900` (dark), `stone-50` (light)
- Text: `stone-900` (primary), `stone-700` (secondary), `stone-500` (muted)
- Borders: `stone-200` (default), `stone-100` (subtle)
- Success: `emerald-100`/`emerald-700`
- Warning: `amber-100`/`amber-700`
- Error: `red-100`/`red-700`, `red-500`/`red-600`

### Spacing
- Use consistent spacing scale: `p-2`, `p-4`, `p-6`, `p-8`
- Use `gap-*` for flex/grid spacing
- Use `mb-*` for vertical rhythm between elements

```tsx
// Good - consistent spacing
<div className="p-8">
  <div className="mb-8 flex items-center justify-between">
    <h1>Title</h1>
  </div>
  <div className="flex gap-4">
    {/* items */}
  </div>
</div>
```

### Typography
- Headings: `text-2xl font-semibold` (h1), `text-xl font-medium` (h2)
- Body: `text-stone-700` (primary), `text-stone-500` (secondary)
- Monospace: `font-mono` for numbers, codes

```tsx
// Good - typography
<h1 className="text-2xl font-semibold text-stone-900">Page Title</h1>
<p className="text-stone-500 mt-1">Description text</p>
<span className="font-mono font-medium">{invoice.number}</span>
```

### Interactive States
- Hover: `hover:bg-stone-50`, `hover:text-stone-600`
- Focus: Use Tailwind focus utilities or Radix focus-visible
- Transitions: `transition-colors` for color changes

```tsx
// Good - interactive states
<button className="px-4 py-2 bg-stone-900 text-white hover:bg-stone-800 transition-colors">
  Submit
</button>

<tr className="cursor-pointer hover:bg-stone-50 transition-colors">
  {/* row content */}
</tr>
```

### Badges and Pills
- Use rounded backgrounds with appropriate colors
- Consistent padding: `px-2.5 py-1`

```tsx
// Good - status badges
<span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-emerald-100 text-emerald-700">
  Final
</span>
<span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-amber-100 text-amber-700">
  Draft
</span>
```

### Layout Patterns
- Container: `max-w-7xl mx-auto`
- Cards: `bg-white rounded-xl border border-stone-200`
- Page wrapper: `p-8`

```tsx
// Good - card layout
<div className="bg-white rounded-xl border border-stone-200">
  <Table>
    {/* table content */}
  </Table>
</div>
```

### Responsive Design
- Mobile-first approach with breakpoint modifiers
- Common breakpoints: `sm:`, `md:`, `lg:`

```tsx
// Good - responsive
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
  {/* grid items */}
</div>
```
