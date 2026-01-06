Instruktionsbok
DeskOS – Ett desktop-liknande system i iOS/iPadOS
Version: Koncept & MVP-specifikation
Status: Spånad → Klar för design & byggstart
1. Översikt

DeskOS är en iOS/iPadOS-app som skapar en desktop-upplevelse när enheten används med:

extern skärm (HDMI / AirPlay),

mus eller trackpad,

tangentbord.

Systemet efterliknar ett förenklat operativsystem (inspirerat av Samsung DeX), men körs helt inom en app och följer Apples plattformregler.

DeskOS är inte ett riktigt operativsystem, utan ett desktop-skal där flera inbyggda “appar” (moduler) körs i flyttbara fönster.

2. Grundidé och användningssätt
2.1 Primärt användningsläge

Extern skärm
Visar DeskOS Desktop i fullskärm:

arbetsyta

dock

fönster

iPhone / iPad
Fungerar som:

controller (trackpad, tangentbord, launcher)

eller extra panel

2.2 Sekundärt läge (utan extern skärm)

iPad kan visa Desktop direkt i helskärm

iPhone visar en förenklad variant (en app i taget)

3. Desktop-miljö
3.1 Arbetsyta

Bakgrund (kan vara tema- eller säsongsstyrd)

Valfria skrivbordsikoner

Fri yta där fönster kan placeras

3.2 Dock

Placerad längst ned (eller sida i framtiden)

Innehåller:

Launcher

öppna appar

snabbåtkomst

4. Launcher (Appmeny)

Launcher är systemets “Startmeny”.

Funktioner:

Visar alla tillgängliga appar (moduler)

Sökfunktion (⌘K)

Senast använda appar överst

Öppnar appar i nya fönster

5. Fönstersystem (kärnfunktion)
5.1 Fönster

Varje app körs i ett eget fönster med:

titelrad (ikon + namn)

stängknapp

dragbar titelrad

tydlig fokusmarkering

5.2 Flytta fönster

Klicka och dra i titelraden

Fönstret följer mus/pekare/finger

Aktivt fönster hamnar överst (z-order)

6. Snap-funktion (automatisk halvscreen)
6.1 Snap-beteende

När ett fönster dras mot en kant:

Vänster kant → fönstret fyller vänster halva

Höger kant → fönstret fyller höger halva

Överkant → fönstret maximeras (fullskärm)

6.2 Visuell feedback

Transparent förhandsyta visas innan släpp

När fönstret släpps:

det animeras till sin snapped position

6.3 Fönsterlägen

Normal

Snapped Left

Snapped Right

Maximized

(Minimized – planerad v2)

7. Input & styrning
7.1 Mus / Trackpad

Pekare synlig

Klick = fokus

Drag = flytta fönster

Scroll i fönster

7.2 Tangentbord (OS-känsla)

Rekommenderade genvägar:

⌘K → Launcher / Sök

⌘Tab → Växla aktivt fönster

⌘W → Stäng aktivt fönster

⌘M → Minimera (v2)

⌘← / ⌘→ → Snap vänster/höger

Esc → Avbryt / Clear

7.3 Touch

iPad: fullt stöd

iPhone: begränsat, controller-fokus

8. Appar i DeskOS (moduler)

Alla appar är inbyggda i DeskOS och körs i fönster.

8.1 Grundprincip

Appar är inte riktiga iOS-appar

De är moduler med:

ikon

namn

eget innehåll

eget fönster

9. Ingående appar (MVP)
9.1 Webbläsare

Byggd med WebKit

Flikar

Adressfält

Back / forward / reload

Tangentbordsgenvägar

Känns som Chrome, men är WebKit-baserad

9.2 Mail

Egen mailklient

IMAP / SMTP

Inkorg, läsa, skriva, svara

Konton läggs till i appen

9.3 Kalkylator

Basic-läge:

− × ÷

decimal

C / AC

minne (MC, MR, M+, M-)

Fullt tangentbordsstöd

Liten, flyttbar fönsterstorlek

Scientific + historik i framtida version

9.4 Filer (planerad MVP+)

Appens dokument

Downloads från webbläsaren

Bilagor från mail

9.5 Inställningar

Tema

Input

Skärm- och layoutval

App-beteende

10. Session & ihågkomst

DeskOS beter sig som ett OS genom att:

minnas öppna fönster

spara positioner och snap-status

återställa arbetsytan vid omstart

11. Tekniska och plattformsregler

Alla webbsidor körs via WebKit

Ingen extern exekverbar kod laddas

Alla appar är interna moduler

Systemet följer App Store-regler

DeskOS marknadsförs som:

“En produktivitets- och desktop-upplevelse i en iOS-app”

12. MVP-sammanfattning

MVP ska innehålla:

Desktop + dock + launcher

Flyttbara fönster

Snap vänster/höger + maximera

Webbläsare

Mail

Kalkylator

Mus + tangentbord + genvägar

13. Vidare steg

När detta är godkänt kan nästa steg vara:

Produktkrav (PRD) på 1 sida

UI-skiss per vy

Teknisk arkitektur

Byggstart (WindowManager först)
