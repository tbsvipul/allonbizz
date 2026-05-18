export function SectionCard({
  title,
  description,
  action,
  children,
}: {
  title: string;
  description?: string;
  action?: React.ReactNode;
  children: React.ReactNode;
}) {
  return (
    <section className="panel-card">
      <div className="card-header">
        <div className="card-header-copy">
          <h3>{title}</h3>
          {description ? <p className="muted-text tiny-text">{description}</p> : null}
        </div>
        {action}
      </div>
      {children}
    </section>
  );
}
