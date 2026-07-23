"use client";

import React from "react";

export function AnimatedStars() {
  return (
    <>
      <style>{`
        @keyframes starDrift1 { from { background-position: 0 0; } to { background-position: -200px -200px; } }
        @keyframes starDrift2 { from { background-position: 0 0; } to { background-position: -300px -300px; } }
        @keyframes starDrift3 { from { background-position: 0 0; } to { background-position: -400px -400px; } }
        .stars-1 { animation: starDrift1 15s linear infinite; }
        .stars-2 { animation: starDrift2 25s linear infinite; }
        .stars-3 { animation: starDrift3 35s linear infinite; }
      `}</style>

      {/* ── Night Sky Stars Background (Light Mode) ── */}
      <div className="absolute inset-0 z-0 pointer-events-none dark:hidden opacity-80 overflow-hidden">
        <div className="absolute inset-0 stars-1" style={{ backgroundImage: 'radial-gradient(1px 1px at 20px 30px, #8b5cf6, transparent), radial-gradient(1px 1px at 40px 70px, #8b5cf6, transparent), radial-gradient(1px 1px at 90px 130px, #8b5cf6, transparent), radial-gradient(1.5px 1.5px at 160px 40px, #8b5cf6, transparent)', backgroundSize: '200px 200px' }} />
        <div className="absolute inset-0 stars-2" style={{ backgroundImage: 'radial-gradient(1.5px 1.5px at 50px 160px, #8b5cf6, transparent), radial-gradient(2px 2px at 130px 250px, #8b5cf6, transparent), radial-gradient(1.5px 1.5px at 220px 80px, #8b5cf6, transparent), radial-gradient(2px 2px at 280px 120px, #8b5cf6, transparent)', backgroundSize: '300px 300px' }} />
        <div className="absolute inset-0 stars-3" style={{ backgroundImage: 'radial-gradient(2px 2px at 100px 100px, #8b5cf6, transparent), radial-gradient(2.5px 2.5px at 200px 300px, #8b5cf6, transparent), radial-gradient(2px 2px at 350px 50px, #8b5cf6, transparent), radial-gradient(3px 3px at 300px 250px, #8b5cf6, transparent)', backgroundSize: '400px 400px' }} />
      </div>

      {/* ── Night Sky Stars Background (Dark Mode) ── */}
      <div className="absolute inset-0 z-0 pointer-events-none hidden dark:block opacity-70 overflow-hidden">
        <div className="absolute inset-0 stars-1" style={{ backgroundImage: 'radial-gradient(1px 1px at 20px 30px, #ffffff, transparent), radial-gradient(1px 1px at 40px 70px, #ffffff, transparent), radial-gradient(1px 1px at 90px 130px, #ffffff, transparent), radial-gradient(1.5px 1.5px at 160px 40px, #ffffff, transparent)', backgroundSize: '200px 200px' }} />
        <div className="absolute inset-0 stars-2" style={{ backgroundImage: 'radial-gradient(1.5px 1.5px at 50px 160px, #ffffff, transparent), radial-gradient(2px 2px at 130px 250px, #ffffff, transparent), radial-gradient(1.5px 1.5px at 220px 80px, #ffffff, transparent), radial-gradient(2px 2px at 280px 120px, #ffffff, transparent)', backgroundSize: '300px 300px' }} />
        <div className="absolute inset-0 stars-3" style={{ backgroundImage: 'radial-gradient(2px 2px at 100px 100px, #ffffff, transparent), radial-gradient(2.5px 2.5px at 200px 300px, #ffffff, transparent), radial-gradient(2px 2px at 350px 50px, #ffffff, transparent), radial-gradient(3px 3px at 300px 250px, #ffffff, transparent)', backgroundSize: '400px 400px' }} />
      </div>
    </>
  );
}
