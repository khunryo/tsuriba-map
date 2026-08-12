(() => {
  const capacitor = window.capacitorExports?.Capacitor || window.Capacitor;
  const admob = window.capacitorStripe?.AdMob;

  if (!capacitor?.isNativePlatform?.() || !admob) return;

  const addPrivacyOptions = () => {
    const legalLinks = document.querySelector(".legal-links");
    if (!legalLinks || document.querySelector("[data-ad-privacy]")) return;

    const button = document.createElement("button");
    button.type = "button";
    button.dataset.adPrivacy = "true";
    button.textContent = "Ad privacy settings";
    button.style.cssText = "border:0;padding:0;background:transparent;color:#64e4d2;font:inherit;text-decoration:underline;cursor:pointer";
    button.addEventListener("click", async () => {
      try {
        await admob.showPrivacyOptionsForm();
      } catch (error) {
        console.warn("Ad privacy options are unavailable", error);
      }
    });
    legalLinks.append(button);
  };

  const startAds = async () => {
    try {
      await admob.initialize({
        tagForChildDirectedTreatment: false,
        tagForUnderAgeOfConsent: false,
        maxAdContentRating: "Teen",
      });

      let consent = await admob.requestConsentInfo();
      if (consent.isConsentFormAvailable && consent.status === "REQUIRED") {
        consent = await admob.showConsentForm();
      }

      if (consent.privacyOptionsRequirementStatus === "REQUIRED") {
        addPrivacyOptions();
      }
      if (!consent.canRequestAds) return;

      await admob.showBanner({
        adId: "ca-app-pub-6124353053548665/5394977614",
        adSize: "ADAPTIVE_BANNER",
        position: "BOTTOM_CENTER",
        margin: 78,
        npa: true,
        isTesting: Boolean(capacitor.DEBUG),
      });
    } catch (error) {
      console.warn("AdMob could not be started", error);
    }
  };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", startAds, { once: true });
  } else {
    startAds();
  }
})();
