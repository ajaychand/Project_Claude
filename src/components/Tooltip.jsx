import { useId } from "react";

/**
 * Hover/focus tooltip styled to match the JobPortal design
 * (dark glass panel, primary → purple gradient accent).
 *
 * Usage: <Tooltip title="Heading" content="Body text"><button>…</button></Tooltip>
 * The child should be focusable so keyboard users get the tooltip too.
 */
const Tooltip = ({ title, content, children, className = "" }) => {
  const id = useId();

  return (
    <span className={`group/tip relative inline-flex ${className}`}>
      <span aria-describedby={id} className="inline-flex">
        {children}
      </span>

      <span
        id={id}
        role="tooltip"
        className="pointer-events-none invisible absolute bottom-full left-0 z-50 mb-3 w-64 max-w-[calc(100vw-2rem)] translate-y-1 opacity-0 transition-all duration-300 md:left-1/2 md:-translate-x-1/2 group-hover/tip:visible group-hover/tip:translate-y-0 group-hover/tip:opacity-100 group-focus-within/tip:visible group-focus-within/tip:translate-y-0 group-focus-within/tip:opacity-100"
      >
        <span className="relative block overflow-hidden rounded-xl border border-gray-700/60 bg-gray-900/95 p-4 text-left shadow-2xl shadow-black/40 backdrop-blur-md">
          <span className="absolute inset-x-0 top-0 h-0.5 bg-gradient-to-r from-primary-500 via-purple-500 to-primary-500" />
          {title && (
            <span className="mb-1 block text-sm font-bold bg-gradient-to-r from-primary-400 to-purple-400 bg-clip-text text-transparent">
              {title}
            </span>
          )}
          <span className="block text-xs leading-relaxed text-gray-300">
            {content}
          </span>
        </span>
        {/* Arrow */}
        <span className="absolute left-6 top-full -mt-1.5 h-3 w-3 rotate-45 border-b border-r border-gray-700/60 bg-gray-900/95 md:left-1/2 md:-translate-x-1/2" />
      </span>
    </span>
  );
};

export default Tooltip;
