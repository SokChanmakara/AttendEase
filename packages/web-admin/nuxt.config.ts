export default defineNuxtConfig({
    devtools: { enabled: true },
    modules: ['@vueuse/motion/nuxt'],
    css: ['~/assets/css/main.css'],
    runtimeConfig: {
        public: {
            firebaseApiKey: process.env.NUXT_PUBLIC_FIREBASE_API_KEY ?? '',
            firebaseAuthDomain: process.env.NUXT_PUBLIC_FIREBASE_AUTH_DOMAIN ?? '',
            firebaseProjectId: process.env.NUXT_PUBLIC_FIREBASE_PROJECT_ID ?? '',
            firebaseAppId: process.env.NUXT_PUBLIC_FIREBASE_APP_ID ?? '',
            firebaseFunctionsRegion: process.env.NUXT_PUBLIC_FIREBASE_FUNCTIONS_REGION ?? 'us-central1'
        }
    },
    app: {
        head: {
            title: 'AttendEase Admin',
            link: [
                { rel: 'preconnect', href: 'https://fonts.googleapis.com' },
                { rel: 'preconnect', href: 'https://fonts.gstatic.com', crossorigin: '' },
                { rel: 'stylesheet', href: 'https://fonts.googleapis.com/css2?family=DM+Serif+Display&family=IBM+Plex+Mono:wght@400;500;600&family=Inter:wght@400;500&display=swap' }
            ]
        }
    }

});

