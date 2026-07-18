import {
  Navbar,
  HeroSection,
  LogosSection,
  FeaturesSection,
  HowItWorksSection,
  StatsTestimonialSection,
  CTASection,
} from "@/components/home";

export default function Home() {
  return (
    <div className="flex min-h-screen flex-col">
      <Navbar />
      <main className="flex-1">
        <HeroSection />
        <LogosSection />
        <FeaturesSection />
        <HowItWorksSection />
        <StatsTestimonialSection />
        <CTASection />
      </main>
    </div>
  );
}
