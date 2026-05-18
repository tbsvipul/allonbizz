interface AuthHeroProps {
  eyebrow: string;
  title: string;
  description: string;
  points: string[];
}

export function AuthHero({ eyebrow, title, description, points }: AuthHeroProps) {
  return (
    <section className="auth-hero">
      <div style={{ display: 'grid', gap: '1.4rem' }}>
        <span className="brand-badge">{eyebrow}</span>
        <div style={{ display: 'grid', gap: '1rem' }}>
          <h1>{title}</h1>
          <p>{description}</p>
        </div>
      </div>

      <div className="field-stack">
        {points.map((point) => (
          <div key={point} className="document-item" style={{ background: 'rgba(255,255,255,0.12)', color: 'white' }}>
            <p>{point}</p>
          </div>
        ))}
      </div>
    </section>
  );
}
