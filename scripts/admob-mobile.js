(() => {
  const capacitor = window.capacitorExports?.Capacitor || window.Capacitor;
  const admob = window.capacitorStripe?.AdMob;
  const platform = capacitor?.getPlatform?.() || "web";

  if (!capacitor?.isNativePlatform?.() || !admob) return;

  const defaultBannerHeight = 50;

  const setBannerLayout = (height = defaultBannerHeight) => {
    const measuredHeight = Number(height);
    const bannerHeight = Number.isFinite(measuredHeight) && measuredHeight > 0
      ? Math.ceil(measuredHeight)
      : defaultBannerHeight;

    document.body.style.setProperty("--native-ad-height", `${bannerHeight}px`);
    document.body.classList.add("has-native-banner");
  };

  const clearBannerLayout = () => {
    document.body.classList.remove("has-native-banner");
    document.body.style.removeProperty("--native-ad-height");
  };

  const listenForBannerLayout = async () => {
    try {
      await Promise.all([
        admob.addListener("bannerAdSizeChanged", ({ height }) => {
          if (Number(height) > 0) setBannerLayout(height);
          else clearBannerLayout();
        }),
        admob.addListener("bannerAdLoaded", () => {
          if (!document.body.classList.contains("has-native-banner")) setBannerLayout();
        }),
        admob.addListener("bannerAdFailedToLoad", clearBannerLayout),
      ]);
    } catch (error) {
      console.warn("AdMob banner layout events are unavailable", error);
    }
  };

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

      const bannerAdId = platform === "android"
        ? "__ADMOB_ANDROID_BANNER_ID__"
        : "ca-app-pub-6124353053548665/5394977614";

      await listenForBannerLayout();
      await admob.showBanner({
        adId: bannerAdId,
        adSize: "ADAPTIVE_BANNER",
        position: "BOTTOM_CENTER",
        margin: 0,
        npa: true,
        isTesting: Boolean(capacitor.DEBUG) || bannerAdId.startsWith("ca-app-pub-3940256099942544/"),
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
