export function PageHeader({
  title,
  description,
  actions,
}: {
  title: string;
  description: string;
  actions?: React.ReactNode;
}) {
  return (
    <div className="page-header">
      <div className="page-header-copy">
        <span className="page-kicker">Keeper workspace</span>
        <h2>{title}</h2>
        <p className="muted-text">{description}</p>
      </div>
      {actions ? <div className="page-actions">{actions}</div> : null}
    </div>
  );
}
