function MyPMPC()
%% ═══════════════════════════════════════════════════════════════════════════
%  MyPMPC  –  Post-traitement Mesure & Simulation d'Antennes
%  XLIM / Université de Limoges
%  ───────────────────────────────────────────────────────────────────────────
%  Structure attendue du working directory (ex : antenne_pixel_sans_steel) :
%    ├── MyPMPC.m
%    ├── logo_xlim.png
%    ├── logo_universite.png
%    ├── mesure/
%    │   ├── Ehoriz/   (dir_PPP_FFF.amp + .pha)
%    │   ├── Evert/    (idem)
%    │   └── *.S2P
%    │   └── image_proto.PNG
%    └── simulation/
%        ├── Farfield/ (farfield_source_(f=F)_[1].ffs)
%        ├── *.stl
%        ├── s11.s2p en RI  (fichier texte CST)
%        └── Hi.png
%% ═══════════════════════════════════════════════════════════════════════════

%% ── Données globales de l'application 
app.workingDir  = '';
app.simuDone    = false;
app.mesuDone    = false;
app.s11Mode     = 'mes';
app.ffMode      = 'mes';
app.gainMode    = 'mes';

% Données simulation
app.s11_simu.freq = [];
app.s11_simu.S11  = [];
app.ff_simu.freq   = [];
app.ff_simu.theta  = [];
app.ff_simu.phi    = [];
app.ff_simu.Etheta = [];
app.ff_simu.Ephi   = [];
app.ff_simu.Prad   = [];
app.ff_simu.Pacc   = [];
app.ff_simu.Pstim  = [];
app.stl_mesh       = [];

% Données mesure
app.s11_mesu.freq = [];
app.s11_mesu.S11  = [];
app.ff_mesu = app.ff_simu;

%% ── Palette de couleurs 
C_DARK_RED    = [0.55 0.00 0.10];
C_ORANGE      = [0.95 0.60 0.10];
C_BLUE_LOGO   = [0.53 0.71 0.87];
C_WHITE       = [1.00 1.00 1.00];
C_BLACK       = [0.00 0.00 0.00];
C_LIGHT_GRAY  = [0.93 0.93 0.93];
C_TAB_INACT   = [0.85 0.85 0.85];

%% ════════════════════════════════════════════════════════════════════════
%                         FIGURE PRINCIPALE
%% ════════════════════════════════════════════════════════════════════════
fig = figure('Name','MyPMPC','NumberTitle','off',...
    'MenuBar','none','ToolBar','none',...
    'Color',C_WHITE,...
    'Units','normalized','Position',[0.03 0.03 0.94 0.92],...
    'Resize','on');

hHdr = uipanel('Parent',fig,'BackgroundColor',C_WHITE,...
    'BorderType','none','Units','normalized','Position',[0 0.88 1 0.12]);

% Chemin du répertoire du fichier (pour trouver les logos)
try
    appDir = fileparts(which('MyPMPC'));
catch
    appDir = pwd;
end

% Logo XLIM (gauche)
axLogoXlim = axes('Parent',hHdr,'Units','normalized',...
    'Position',[0.01 0.08 0.18 0.84]);
axis(axLogoXlim,'off');
logoXlimPath = fullfile(appDir,'logo_xlim.jpg');
if exist(logoXlimPath,'file')
    imshow(imread(logoXlimPath),'Parent',axLogoXlim);
else
    uicontrol('Parent',hHdr,'Style','text','String','Logo XLIM',...
        'BackgroundColor',C_BLUE_LOGO,'ForegroundColor',C_BLACK,...
        'FontSize',12,'FontWeight','bold',...
        'Units','normalized','Position',[0.01 0.15 0.18 0.70]);
end

% Titre central
uicontrol('Parent',hHdr,'Style','text',...
    'String',sprintf('\t\t\t\t\tMyPMPC\nPost-traitement Mesure & Simulation d''Antennes'),...
    'BackgroundColor',C_BLUE_LOGO,'ForegroundColor',C_BLACK,...
    'FontSize',12,'FontWeight','bold',...
    'Units','normalized','Position',[0.25 0.10 0.50 0.80]);

% Logo Université (droite)
axLogoUniv = axes('Parent',hHdr,'Units','normalized',...
    'Position',[0.81 0.08 0.18 0.84]);
axis(axLogoUniv,'off');
logoUnivPath = fullfile(appDir,'logo_universite.png');
if exist(logoUnivPath,'file')
    imshow(imread(logoUnivPath),'Parent',axLogoUniv);
else
    uicontrol('Parent',hHdr,'Style','text','String','Logo Universite de Limoges',...
        'BackgroundColor',C_BLUE_LOGO,'ForegroundColor',C_BLACK,...
        'FontSize',12,'FontWeight','bold',...
        'Units','normalized','Position',[0.81 0.15 0.18 0.70]);
end

%% ── BARRE D'ONGLETS ──────────────────────────────────────────────────────
tabLabels = {'Home','Vue 3D de l''AST','S11, Z11 et TE',...
    'Rayonnement champ lointain','Gain et Directivite','Champ Hi - ferrite'};
tabKeys   = {'home','vue3d','s11','farfield','gain','champ'};
nTabs     = numel(tabLabels);
tabW      = 1/nTabs;

hTabBar = uipanel('Parent',fig,'BackgroundColor',C_LIGHT_GRAY,...
    'BorderType','line','HighlightColor',[0.6 0.6 0.6],...
    'Units','normalized','Position',[0 0.80 1 0.08]);

app.tabBtns = gobjects(1,nTabs);
for k = 1:nTabs
    app.tabBtns(k) = uicontrol('Parent',hTabBar,'Style','pushbutton',...
        'String',tabLabels{k},...
        'BackgroundColor',tern(k==1,C_ORANGE,C_TAB_INACT),...
        'ForegroundColor',C_BLACK,...
        'FontSize',8,'FontWeight','bold',...
        'Units','normalized',...
        'Position',[(k-1)*tabW+0.002 0.05 tabW-0.004 0.90],...
        'UserData',tabKeys{k},'Callback',@(s,~) switchTab(s));
end

%% ── ZONE CONTENU ─────────────────────────────────────────────────────────
app.hContent = uipanel('Parent',fig,'BackgroundColor',C_WHITE,...
    'BorderType','none','Units','normalized','Position',[0 0 1 0.80]);

showHome();

%% ════════════════════════════════════════════════════════════════════════
%                        GESTION DES ONGLETS
%% ════════════════════════════════════════════════════════════════════════
    function switchTab(src)
        for i = 1:nTabs
            set(app.tabBtns(i),'BackgroundColor',C_TAB_INACT,...
                'ForegroundColor',C_BLACK);
        end
        set(src,'BackgroundColor',C_ORANGE,'ForegroundColor',C_BLACK);
        delete(get(app.hContent,'Children'));
        switch get(src,'UserData')
            case 'home',     showHome();
            case 'vue3d',    showVue3D();
            case 's11',      showS11();
            case 'farfield', showFarfield();
            case 'gain',     showGain();
            case 'champ',    showChamp();
        end
    end

%% ════════════════════════════════════════════════════════════════════════
%                           ONGLET HOME
%% ════════════════════════════════════════════════════════════════════════
    function showHome()
        p = app.hContent;
        % Working directory
        uicontrol('Parent',p,'Style','text','String','Working directory',...
            'BackgroundColor',C_ORANGE,'ForegroundColor',C_BLACK,...
            'FontSize',11,'FontWeight','bold',...
            'Units','normalized','Position',[0.02 0.88 0.18 0.06]);
        app.hWDEdit = uicontrol('Parent',p,'Style','edit',...
            'String',app.workingDir,...
            'BackgroundColor',C_WHITE,'ForegroundColor',C_BLACK,...
            'FontSize',10,'HorizontalAlignment','left',...
            'Units','normalized','Position',[0.21 0.88 0.53 0.06]);
        uicontrol('Parent',p,'Style','pushbutton','String','Parcourir...',...
            'BackgroundColor',C_ORANGE,'ForegroundColor',C_BLACK,...
            'FontSize',10,'FontWeight','bold',...
            'Units','normalized','Position',[0.75 0.88 0.12 0.06],...
            'Callback',@browseWorkingDir);

        % Panneau mesure
        pMes = uipanel('Parent',p,'Title','Valeur des parametres de la mesure',...
            'TitlePosition','lefttop','ForegroundColor',C_WHITE,...
            'BackgroundColor',C_DARK_RED,...
            'FontSize',10,'FontWeight','bold',...
            'Units','normalized','Position',[0.02 0.52 0.60 0.33]);
        app.hMes = buildParamPanel(pMes);

        % Panneau simulation
        pSim = uipanel('Parent',p,'Title','Valeur des parametres de la simulation',...
            'TitlePosition','lefttop','ForegroundColor',C_WHITE,...
            'BackgroundColor',C_DARK_RED,...
            'FontSize',10,'FontWeight','bold',...
            'Units','normalized','Position',[0.02 0.14 0.60 0.33]);
        app.hSim = buildParamPanel(pSim);

        % Boutons post-traitement
        app.hBtnMes = uicontrol('Parent',p,'Style','pushbutton',...
            'String','Post-traitement des mesures',...
            'BackgroundColor',C_ORANGE,'ForegroundColor',C_BLACK,...
            'FontSize',11,'FontWeight','bold',...
            'Units','normalized','Position',[0.65 0.72 0.26 0.09],...
            'Callback',@postTraitementMesure);
        app.hDoneMes = uicontrol('Parent',p,'Style','text','String','done !',...
            'BackgroundColor',C_WHITE,'ForegroundColor',[0 0.6 0],...
            'FontSize',12,'FontWeight','bold',...
            'Units','normalized','Position',[0.92 0.72 0.07 0.09],...
            'Visible',tern(app.mesuDone,'on','off'));

        app.hBtnSim = uicontrol('Parent',p,'Style','pushbutton',...
            'String',sprintf('Post-traitement des\nsimulations'),...
            'BackgroundColor',C_ORANGE,'ForegroundColor',C_BLACK,...
            'FontSize',11,'FontWeight','bold',...
            'Units','normalized','Position',[0.65 0.55 0.26 0.09],...
            'Callback',@postTraitementSimu);
        app.hDoneSim = uicontrol('Parent',p,'Style','text','String','done !',...
            'BackgroundColor',C_WHITE,'ForegroundColor',[0 0.6 0],...
            'FontSize',12,'FontWeight','bold',...
            'Units','normalized','Position',[0.92 0.55 0.07 0.09],...
            'Visible',tern(app.simuDone,'on','off'));

        refreshParamPanels();
    end

    function h = buildParamPanel(parent)
        lblS = {'Style','text','BackgroundColor',C_DARK_RED,...
                'ForegroundColor',C_WHITE,'FontSize',9,'FontWeight','bold'};
        edtS = {'Style','edit','BackgroundColor',[0.92 0.92 0.92],...
                'ForegroundColor',C_BLACK,'FontSize',9,'String','0'};
        rows = {'Freq_min (GHz)','Freq_max (GHz)','Pas_Freq (GHz)';
                'Theta_min (deg)','Theta_max (deg)','Pas_theta (deg)';
                'Phi_min (deg)','Phi_max (deg)','Pas_Phi (deg)'};
        xL = [0.02 0.36 0.68]; xE = [0.17 0.51 0.83];
        yPos = [0.64 0.38 0.11];
        flds = {'FreqMin','FreqMax','PasFreq',...
                'ThetaMin','ThetaMax','PasTheta',...
                'PhiMin','PhiMax','PasPhi'};
        idx = 1; h = struct();
        for r = 1:3
            for c = 1:3
                uicontrol('Parent',parent,lblS{:},'String',rows{r,c},...
                    'Units','normalized','Position',[xL(c) yPos(r) 0.14 0.18]);
                h.(flds{idx}) = uicontrol('Parent',parent,edtS{:},...
                    'Units','normalized','Position',[xE(c) yPos(r) 0.10 0.18]);
                idx = idx+1;
            end
        end
    end

    function refreshParamPanels()
        if ~isempty(app.ff_mesu.freq) && isfield(app,'hMes')
            fillPanel(app.hMes, app.ff_mesu);
        end
        if ~isempty(app.ff_simu.freq) && isfield(app,'hSim')
            fillPanel(app.hSim, app.ff_simu);
        end
    end

    function fillPanel(h, ff)
        set(h.FreqMin, 'String', num2str(min(ff.freq),4));
        set(h.FreqMax, 'String', num2str(max(ff.freq),4));
        if numel(ff.freq)>1
            set(h.PasFreq,'String', num2str(ff.freq(2)-ff.freq(1),4));
        end
        if ~isempty(ff.theta)
            set(h.ThetaMin,'String', num2str(min(ff.theta),4));
            set(h.ThetaMax,'String', num2str(max(ff.theta),4));
            if numel(ff.theta)>1
                set(h.PasTheta,'String', num2str(ff.theta(2)-ff.theta(1),4));
            end
        end
        if ~isempty(ff.phi)
            set(h.PhiMin,'String', num2str(min(ff.phi),4));
            set(h.PhiMax,'String', num2str(max(ff.phi),4));
            if numel(ff.phi)>1
                set(h.PasPhi,'String', num2str(ff.phi(2)-ff.phi(1),4));
            end
        end
    end

%% ════════════════════════════════════════════════════════════════════════
%                         ONGLET VUE 3D
%% ════════════════════════════════════════════════════════════════════════
    function showVue3D()
        p = app.hContent;

        %% Titre
        uicontrol('Parent',p,'Style','text','String','Vue 3D de l''antenne (AST)',...
            'BackgroundColor',C_WHITE,'ForegroundColor',C_BLACK,...
            'FontSize',13,'FontWeight','bold',...
            'Units','normalized','Position',[0.25 0.93 0.50 0.06]);

        %% Axe STL — colonne gauche
        uicontrol('Parent',p,'Style','text','String','Modele numerique (.stl)',...
            'BackgroundColor',C_WHITE,'ForegroundColor',[0.3 0.3 0.3],...
            'FontSize',9,'FontWeight','bold',...
            'Units','normalized','Position',[0.02 0.88 0.45 0.04]);
        app.hAxes3D = axes('Parent',p,...
            'Units','normalized','Position',[0.02 0.10 0.46 0.77],...
            'Color',C_LIGHT_GRAY);
        title(app.hAxes3D,'Lancez le post-traitement simulation pour charger le modele',...
            'FontSize',9,'Color',[0.5 0.5 0.5]);
        axis(app.hAxes3D,'equal'); grid(app.hAxes3D,'on'); view(app.hAxes3D,[-45 25]);

        %% Axe photo — colonne droite
        uicontrol('Parent',p,'Style','text','String','Prototype reel (photo)',...
            'BackgroundColor',C_WHITE,'ForegroundColor',[0.3 0.3 0.3],...
            'FontSize',9,'FontWeight','bold',...
            'Units','normalized','Position',[0.52 0.88 0.45 0.04]);
        app.hAxesPhoto = axes('Parent',p,...
            'Units','normalized','Position',[0.52 0.10 0.46 0.77],...
            'Color',C_LIGHT_GRAY);
        axis(app.hAxesPhoto,'off');
        text(0.5, 0.5, sprintf('Chargez une photo\ndu prototype'),...
            'Parent',app.hAxesPhoto,...
            'HorizontalAlignment','center','FontSize',11,...
            'Color',[0.6 0.6 0.6],'Units','normalized');

        %% Boutons (bas)
        uicontrol('Parent',p,'Style','pushbutton',...
            'String','Charger modele 3D (.stl)',...
            'BackgroundColor',C_ORANGE,'ForegroundColor',C_BLACK,...
            'FontSize',9,'FontWeight','bold',...
            'Units','normalized','Position',[0.02 0.02 0.46 0.06],...
            'Callback',@loadStlManual);

        uicontrol('Parent',p,'Style','pushbutton',...
            'String','Charger photo du prototype',...
            'BackgroundColor',C_ORANGE,'ForegroundColor',C_BLACK,...
            'FontSize',9,'FontWeight','bold',...
            'Units','normalized','Position',[0.52 0.02 0.46 0.06],...
            'Callback',@loadProtoPhoto);

        %% Chargement automatique si données déjà disponibles
        if ~isempty(app.stl_mesh), render3D(); end
        autoLoadProtoPhoto();
    end

    function loadStlManual(~,~)
        sd = fullfile(app.workingDir,'simulation');
        if ~isfolder(sd), sd = app.workingDir; end
        [f,d] = uigetfile({'*.stl','Fichier STL (*.stl)';'*.*','Tous les fichiers'},...
            'Charger le modele 3D (.stl)', sd);
        if isequal(f,0), return; end
        try
            app.stl_mesh = stlread(fullfile(d,f));
            render3D();
        catch ME
            errordlg(['Erreur lecture STL : ' ME.message],'Erreur');
        end
    end

    function loadProtoPhoto(~,~)
        sd = tern(~isempty(app.workingDir), app.workingDir, pwd);
        [f,d] = uigetfile({'*.png;*.jpg;*.jpeg;*.bmp','Images (*.png,*.jpg,*.bmp)';...
                           '*.*','Tous les fichiers'},...
            'Charger la photo du prototype', sd);
        if isequal(f,0), return; end
        try
            img = imread(fullfile(d,f));
            imshow(img,'Parent',app.hAxesPhoto);
            title(app.hAxesPhoto, f, 'FontSize',9, 'Interpreter','none');
        catch ME
            errordlg(['Erreur chargement image : ' ME.message],'Erreur');
        end
    end

    function autoLoadProtoPhoto()
        %% Chercher dans mesure/ en priorité, puis dans le working dir
        if isempty(app.workingDir), return; end
        mesDir = fullfile(app.workingDir,'mesure');
        wd     = app.workingDir;
        searchDirs = {mesDir, wd, mesDir, wd};
        patterns   = {'image_proto.*','image_proto.*',...
                      'prototype.*','prototype.*'};
        candidates = [];
        for si = 1:numel(searchDirs)
            if ~isfolder(searchDirs{si}), continue; end
            hits = dir(fullfile(searchDirs{si}, patterns{si}));
            % Garder seulement les images
            for hi = 1:numel(hits)
                [~,~,ext] = fileparts(hits(hi).name);
                if any(strcmpi(ext,{'.png','.jpg','.jpeg','.bmp'}))
                    hits(hi).folder = searchDirs{si};
                    candidates = [candidates; hits(hi)]; %#ok<AGROW>
                end
            end
            if ~isempty(candidates), break; end
        end
        if ~isempty(candidates)
            try
                img = imread(fullfile(candidates(1).folder, candidates(1).name));
                imshow(img,'Parent',app.hAxesPhoto);
                title(app.hAxesPhoto, candidates(1).name,'FontSize',9,'Interpreter','none');
            catch; end
        end
    end

    function render3D()
        ax = app.hAxes3D;
        cla(ax);
        tr  = app.stl_mesh;
        pts = tr.Points;
        tri = tr.ConnectivityList;

        %% Rendu gris uniforme (pas de colormap)
        patch('Faces',tri,'Vertices',pts,...
            'FaceColor',[0.75 0.75 0.75],...
            'EdgeColor','none',...
            'Parent',ax);

        %% Éclairage
        axes(ax);
        camlight('headlight');
        camlight('left');
        lighting gouraud;
        material dull;

        %% Axes et grille
        axis(ax,'equal','tight');
        grid(ax,'on');
        xlabel(ax,'X (mm)'); ylabel(ax,'Y (mm)'); zlabel(ax,'Z (mm)');
        set(ax,'FontSize',9);

        %% Dimensions de la boite englobante
        xr = [min(pts(:,1)) max(pts(:,1))];
        yr = [min(pts(:,2)) max(pts(:,2))];
        zr = [min(pts(:,3)) max(pts(:,3))];
        Hx = xr(2)-xr(1);  Hy = yr(2)-yr(1);  Hz = zr(2)-zr(1);

        title(ax, sprintf('Hx = %.1f mm     Hy = %.1f mm     Hz = %.1f mm',...
            Hx, Hy, Hz), 'FontSize',10);
        view(ax,[-45 25]);
        rotate3d(ax,'on');
    end

%% ════════════════════════════════════════════════════════════════════════
%                      ONGLET S11 / Z11 / TE
%% ════════════════════════════════════════════════════════════════════════
    function showS11()
        p = app.hContent;
        app.s11Mode = 'mes';
        subL = {'mesure','simulation','simu Vs mesu'};
        subK = {'mes','sim','vs'};
        app.hSubS11 = gobjects(1,3);
        for k=1:3
            app.hSubS11(k) = uicontrol('Parent',p,'Style','pushbutton',...
                'String',subL{k},...
                'BackgroundColor',tern(k==1,C_ORANGE,C_TAB_INACT),...
                'ForegroundColor',C_BLACK,'FontSize',9,'FontWeight','bold',...
                'Units','normalized','Position',[0.02+(k-1)*0.17 0.91 0.15 0.07],...
                'UserData',subK{k},'Callback',@(s,~) switchSubS11(s));
        end
        % Bouton Curseurs
        app.hS11Cursor = uicontrol('Parent',p,'Style','togglebutton',...
            'String','Curseurs OFF',...
            'BackgroundColor',C_TAB_INACT,'ForegroundColor',C_BLACK,...
            'FontSize',9,'FontWeight','bold',...
            'Units','normalized','Position',[0.57 0.91 0.14 0.07],...
            'Value',0,'Callback',@toggleCursorS11);

        app.hAxS11   = axes('Parent',p,'Units','normalized','Position',[0.05 0.52 0.4 0.35]);
        cfgAx(app.hAxS11,'Frequence (GHz)','S11 (dB)','S11');
        app.hAxZ11   = axes('Parent',p,'Units','normalized','Position',[0.05 0.06 0.4 0.35]);
        cfgAx(app.hAxZ11,'Frequence (GHz)','Z (Ohms)','Z11');
        app.hAxTE    = axes('Parent',p,'Units','normalized','Position',[0.55 0.52 0.4 0.35]);
        cfgAx(app.hAxTE,'Frequence (GHz)','TE (dB)','Taux Ellipticite (boresight)');
        app.hAxS11TE = axes('Parent',p,'Units','normalized','Position',[0.55 0.06 0.4 0.35]);
        cfgAx(app.hAxS11TE,'Frequence (GHz)','','Superposition S11 & TE');

        if app.mesuDone || app.simuDone, plotS11(); end
    end

    function switchSubS11(src)
        for i=1:3; set(app.hSubS11(i),'BackgroundColor',C_TAB_INACT); end
        set(src,'BackgroundColor',C_ORANGE);
        app.s11Mode = get(src,'UserData');
        plotS11();
    end

    function toggleCursorS11(src,~)
        if get(src,'Value')
            set(src,'String','Curseurs ON','BackgroundColor',C_ORANGE);
            datacursormode(fig,'on');
        else
            set(src,'String','Curseurs OFF','BackgroundColor',C_TAB_INACT);
            dcm = datacursormode(fig);
            dcm.removeAllDataCursors();
            datacursormode(fig,'off');
        end
    end

%% ════════════════════════════════════════════════════════════════════════
%                  ONGLET RAYONNEMENT CHAMP LOINTAIN
%% ════════════════════════════════════════════════════════════════════════
    function showFarfield()
    p = app.hContent;
    app.ffMode = 'mes';
    subL = {'mesure','simulation','simu Vs mesu'};
    subK = {'mes','sim','vs'};
    app.hSubFF = gobjects(1,3);

    %% Ligne 1 : sous-onglets | Curseurs | Tracer
    for k = 1:3
        app.hSubFF(k) = uicontrol('Parent',p,'Style','pushbutton',...
            'String',subL{k},...
            'BackgroundColor',tern(k==1,C_ORANGE,C_TAB_INACT),...
            'ForegroundColor',C_BLACK,'FontSize',9,'FontWeight','bold',...
            'Units','normalized','Position',[0.02+(k-1)*0.18 0.93 0.17 0.06],...
            'UserData',subK{k},'Callback',@(s,~) switchSubFF(s));
    end
    app.hFFCursor = uicontrol('Parent',p,'Style','togglebutton',...
        'String','Curseurs OFF',...
        'BackgroundColor',C_TAB_INACT,'ForegroundColor',C_BLACK,...
        'FontSize',9,'FontWeight','bold',...
        'Units','normalized','Position',[0.59 0.93 0.14 0.06],...
        'Value',0,'Callback',@toggleCursorFF);
    uicontrol('Parent',p,'Style','pushbutton','String','Tracer',...
        'BackgroundColor',C_ORANGE,'ForegroundColor',C_BLACK,...
        'FontSize',10,'FontWeight','bold',...
        'Units','normalized','Position',[0.74 0.93 0.24 0.06],...
        'Callback',@plotFarfield);

    %% Ligne 2 : Quantite | Freq | Plan phi
    mkLbl(p,'Quantite :',       0.01, 0.86, 0.09, 0.05);
    app.hFFQty  = mkPop(p,{'AR','XPD','Ephi','Etheta','Eabs','Eright','Eleft'},...
                         0.11, 0.86, 0.14, 0.05);
    mkLbl(p,'Freq (GHz) :',    0.28, 0.86, 0.11, 0.05);
    app.hFFFreq = uicontrol('Parent',p,'Style','edit','String','1.0',...
        'FontSize',9,'Units','normalized','Position',[0.40 0.86 0.11 0.05]);
    mkLbl(p,'Plan phi (deg) :', 0.54, 0.86, 0.14, 0.05);
    app.hFFPhi = uicontrol('Parent',p,'Style','popupmenu',...
        'String',{'0'},'Value',1,...
        'FontSize',9,'Units','normalized','Position',[0.69 0.86 0.11 0.05]);
    updatePhiList();

    %% Axes polaire 
    app.hAxFFPolar = polaraxes('Parent',p,...
        'Units','normalized','Position',[0.01 0.12 0.46 0.64]);  
    title(app.hAxFFPolar,'— tracez pour afficher —','FontSize',9);

    %% Axes cartésien 
    app.hAxFFCart = axes('Parent',p,...
        'Units','normalized','Position',[0.52 0.32 0.46 0.48]);  
    cfgAx(app.hAxFFCart,'Theta (deg)','Amplitude (dBi)','— tracez pour afficher —');

    %% Panneau métriques 
    app.hFFMetrics = uicontrol('Parent',p,'Style','text',...
        'String','Metriques antenne — cliquez Tracer',...
        'BackgroundColor',[0.93 0.93 0.93],'ForegroundColor',[0.1 0.1 0.1],...
        'FontSize',8,'FontWeight','bold','HorizontalAlignment','left',...
        'Units','normalized','Position',[0.52 0.02 0.46 0.2]);  
    end

    function switchSubFF(src)
        for i=1:3; set(app.hSubFF(i),'BackgroundColor',C_TAB_INACT); end
        set(src,'BackgroundColor',C_ORANGE);
        app.ffMode = get(src,'UserData');
        updatePhiList();
        plotFarfield();
    end

    %% ── Popupmenu phi 
    function updatePhiList()
        if ~isfield(app,'hFFPhi') || ~isvalid(app.hFFPhi), return; end
        mode = app.ffMode;
        phiVec = [];
        if strcmp(mode,'mes') && ~isempty(app.ff_mesu.phi)
            phiVec = app.ff_mesu.phi;
        elseif strcmp(mode,'sim') && ~isempty(app.ff_simu.phi)
            phiVec = app.ff_simu.phi;
        elseif strcmp(mode,'vs')
            % En comparaison, prendre la grille mesure qui est plus grande
            if ~isempty(app.ff_mesu.phi)
                phiVec = app.ff_mesu.phi;
            elseif ~isempty(app.ff_simu.phi)
                phiVec = app.ff_simu.phi;
            end
        end
        if isempty(phiVec)
            set(app.hFFPhi,'String',{'0'},'Value',1); return;
        end
        oldVal = get(app.hFFPhi,'Value');
        phiList = arrayfun(@(v) sprintf('%.0f', v), phiVec(:)', 'UniformOutput',false);
        set(app.hFFPhi,'String',phiList,'Value',min(oldVal,numel(phiList)));
    end

    function toggleCursorFF(src,~)
        if get(src,'Value')
            set(src,'String','Curseurs ON','BackgroundColor',C_ORANGE);
            datacursormode(fig,'on');
        else
            set(src,'String','Curseurs OFF','BackgroundColor',C_TAB_INACT);
            dcm = datacursormode(fig);
            dcm.removeAllDataCursors();
            datacursormode(fig,'off');
        end
    end

%% ════════════════════════════════════════════════════════════════════════
%                     ONGLET GAIN ET DIRECTIVITE
%% ════════════════════════════════════════════════════════════════════════
    function showGain()
        p = app.hContent;
        app.gainMode = 'mes';
        subL = {'mesure','simulation','simu Vs mesu'};
        subK = {'mes','sim','vs'};
        app.hSubGain = gobjects(1,3);
        for k=1:3
            app.hSubGain(k) = uicontrol('Parent',p,'Style','pushbutton',...
                'String',subL{k},...
                'BackgroundColor',tern(k==1,C_ORANGE,C_TAB_INACT),...
                'ForegroundColor',C_BLACK,'FontSize',9,'FontWeight','bold',...
                'Units','normalized','Position',[0.02+(k-1)*0.17 0.93 0.15 0.06],...
                'UserData',subK{k},'Callback',@(s,~) switchSubGain(s));
        end
        % Bouton Curseurs
        uicontrol('Parent',p,'Style','togglebutton','String','Curseurs OFF',...
            'BackgroundColor',C_TAB_INACT,'ForegroundColor',C_BLACK,...
            'FontSize',9,'FontWeight','bold',...
            'Units','normalized','Position',[0.57 0.93 0.14 0.06],...
            'Value',0,'Callback',@(s,~) toggleCursorGeneric(s));

        app.hAxGain = axes('Parent',p,'Units','normalized',...
            'Position',[0.05 0.08 0.4 0.70]);
        cfgAx(app.hAxGain,'Frequence (GHz)','Valeur (dB)',...
            'Directivite / Gain IEEE / Gain Realise (valeurs max)');

        app.hAxEff = axes('Parent',p,'Units','normalized',...
            'Position',[0.55 0.08 0.4 0.70]);
        cfgAx(app.hAxEff,'Frequence (GHz)','Efficacite',...
            'Efficacite rayonnee et totale ');

        if app.simuDone || app.mesuDone, plotGain(); end
    end

    function switchSubGain(src)
        for i=1:3; set(app.hSubGain(i),'BackgroundColor',C_TAB_INACT); end
        set(src,'BackgroundColor',C_ORANGE);
        app.gainMode = get(src,'UserData');
        plotGain();
    end

    function toggleCursorGeneric(src)
        if get(src,'Value')
            set(src,'String','Curseurs ON','BackgroundColor',C_ORANGE);
            datacursormode(fig,'on');
        else
            set(src,'String','Curseurs OFF','BackgroundColor',C_TAB_INACT);
            dcm = datacursormode(fig);
            dcm.removeAllDataCursors();
            datacursormode(fig,'off');
        end
    end

%% ════════════════════════════════════════════════════════════════════════
%                         ONGLET CHAMP Hi
%% ════════════════════════════════════════════════════════════════════════
    function showChamp()
        p = app.hContent;
        uicontrol('Parent',p,'Style','text',...
            'String','Champ Hi – ferrite (image de simulation)',...
            'BackgroundColor',C_WHITE,'ForegroundColor',C_BLACK,...
            'FontSize',13,'FontWeight','bold',...
            'Units','normalized','Position',[0.20 0.93 0.60 0.06]);
        % Axe pleine largeur pour l'image Hi
        app.hAxHi = axes('Parent',p,'Units','normalized',...
            'Position',[0.03 0.08 0.94 0.82]);
        axis(app.hAxHi,'off');
        uicontrol('Parent',p,'Style','pushbutton',...
            'String','Charger image Hi (.png) depuis simulation/',...
            'BackgroundColor',C_ORANGE,'ForegroundColor',C_BLACK,...
            'FontSize',10,'FontWeight','bold',...
            'Units','normalized','Position',[0.30 0.01 0.40 0.06],...
            'Callback',@loadChampHi);
        if app.simuDone, autoLoadHi(); end
    end

%% ════════════════════════════════════════════════════════════════════════
%               POST-TRAITEMENT SIMULATION
%% ════════════════════════════════════════════════════════════════════════
    function postTraitementSimu(~,~)
        if isempty(app.workingDir)
            errordlg('Selectionnez d''abord le Working Directory.','Erreur'); return;
        end
        simDir = fullfile(app.workingDir,'simulation');
        if ~isfolder(simDir)
            errordlg('Dossier "simulation" introuvable.','Erreur'); return;
        end
        wb = waitbar(0,'Lecture du modele 3D (.stl)...');
        try
            %% 1. STL
            stlFiles = dir(fullfile(simDir,'*.stl'));
            if ~isempty(stlFiles)
                app.stl_mesh = stlread(fullfile(simDir, stlFiles(1).name));
            end
            waitbar(0.25,wb,'Lecture du S11 simulation...');

            %% 2. S11 (fichier .s1p ou .txt venant de CST)
            % ── Chercher d'abord un .s1p 
            s1p = [dir(fullfile(simDir,'*.s1p')); dir(fullfile(simDir,'*.S1P'))];
            if ~isempty(s1p)
                [fS, Sc] = readS2P(fullfile(simDir, s1p(1).name));   
                if ~isempty(fS)
                    app.s11_simu.freq = fS;
                    app.s11_simu.S11  = Sc;
                end
            end
            
            % ── Sinon, on lit les fichiers texte CST ────────────────────────
            if isempty(app.s11_simu.freq)
                s11Pat = [dir(fullfile(simDir,'S-Parameters*'));...
                          dir(fullfile(simDir,'*S1_1*'));...
                          dir(fullfile(simDir,'*s11*'));...
                          dir(fullfile(simDir,'*.txt'))];
                for fi = 1:numel(s11Pat)
                    [fS, Sc] = readS11txt(fullfile(simDir, s11Pat(fi).name));
                    if ~isempty(fS)
                        app.s11_simu.freq = fS;
                        app.s11_simu.S11  = Sc;
                        break;
                    end
                end
            end

            waitbar(0.5,wb,'Lecture des farfields (.ffs)...');

            %% 3. Farfields FFS
            ffDir = fullfile(simDir,'Farfield');
            if isfolder(ffDir)
                app.ff_simu = readFFSFolder(ffDir, wb);
            end
            waitbar(1.0,wb,'Termine !');
            app.simuDone = true;
            close(wb);
            set(app.hDoneSim,'Visible','on');
            msgbox(sprintf(['Simulation chargee :\n'...
                '  STL      : %s\n'...
                '  S11      : %d points de frequence\n'...
                '  Farfield : %d frequences  |  %d theta  |  %d phi'],...
                tern(~isempty(app.stl_mesh),'OK','non trouve'),...
                numel(app.s11_simu.freq),...
                numel(app.ff_simu.freq),...
                numel(app.ff_simu.theta),...
                numel(app.ff_simu.phi)),...
                'Post-traitement simulation','help');
            refreshParamPanels();
        catch ME
            close(wb);
            errordlg(['Erreur lecture simulation : ' ME.message],'Erreur');
            disp(getReport(ME));
        end
    end

%% ════════════════════════════════════════════════════════════════════════
%               POST-TRAITEMENT MESURE
%% ════════════════════════════════════════════════════════════════════════
    function postTraitementMesure(~,~)
        if isempty(app.workingDir)
            errordlg('Selectionnez d''abord le Working Directory.','Erreur'); return;
        end
        mesDir = fullfile(app.workingDir,'mesure');
        if ~isfolder(mesDir)
            errordlg('Dossier "mesure" introuvable.','Erreur'); return;
        end
        wb = waitbar(0,'Lecture du S11 mesure (.S2P)...');
        try
            %% 1. S11 via .S2P
            s2p = [dir(fullfile(mesDir,'*.S2P')); dir(fullfile(mesDir,'*.s2p'))];
            if ~isempty(s2p)
                [fS,Sc] = readS2P(fullfile(mesDir, s2p(1).name));
                app.s11_mesu.freq = fS;
                app.s11_mesu.S11  = Sc;
            end
            waitbar(0.35,wb,'Lecture des fichiers .amp/.pha (Ehoriz / Evert)...');

            %% 2. Farfield mesure via Ehoriz + Evert
            hDir = fullfile(mesDir,'Ehoriz');
            vDir = fullfile(mesDir,'Evert');
            if isfolder(hDir) && isfolder(vDir)
                app.ff_mesu = readAmpPhaFolders(hDir, vDir, wb);
            end
            waitbar(1.0,wb,'Termine !');
            app.mesuDone = true;
            close(wb);
            set(app.hDoneMes,'Visible','on');
            msgbox(sprintf(['Mesures chargees :\n'...
                '  S11      : %d points de frequence\n'...
                '  Farfield : %d frequences  |  %d theta  |  %d phi'],...
                numel(app.s11_mesu.freq),...
                numel(app.ff_mesu.freq),...
                numel(app.ff_mesu.theta),...
                numel(app.ff_mesu.phi)),...
                'Post-traitement mesure','help');
            refreshParamPanels();
        catch ME
            close(wb);
            errordlg(['Erreur lecture mesure : ' ME.message],'Erreur');
            disp(getReport(ME));
        end
    end

%% ════════════════════════════════════════════════════════════════════════
%                    TRACE  S11 / Z11 / TE
%% ════════════════════════════════════════════════════════════════════════
    function plotS11(~,~)
        if ~isfield(app,'hAxS11') || ~isvalid(app.hAxS11), return; end
        mode  = app.s11Mode;
        doMes  = strcmp(mode,'mes') || strcmp(mode,'vs');
        doSimu = strcmp(mode,'sim') || strcmp(mode,'vs');
        Z0 = 50;

        cla(app.hAxS11); cla(app.hAxZ11); cla(app.hAxTE); cla(app.hAxS11TE);

        %% S11
        ax = app.hAxS11; hold(ax,'on'); grid(ax,'on');
        ylim(ax, [-20 0]);   % ← ajouter

        if doMes && ~isempty(app.s11_mesu.S11)
            plot(ax,app.s11_mesu.freq,20*log10(abs(app.s11_mesu.S11)),...
                'b-','LineWidth',1.5,'DisplayName','S11 mesure');
        end
        if doSimu && ~isempty(app.s11_simu.S11)
            plot(ax,app.s11_simu.freq,20*log10(abs(app.s11_simu.S11)),...
                'r--','LineWidth',1.5,'DisplayName','S11 simule');
        end
        xlabel(ax,'Frequence (GHz)'); ylabel(ax,'S11 (dB)');
        title(ax,'S11'); legend(ax,'Location','best'); hold(ax,'off');

        %% Z11
        ax = app.hAxZ11; hold(ax,'on'); grid(ax,'on');
        if doMes && ~isempty(app.s11_mesu.S11)
            f = app.s11_mesu.freq; Z = Z0*(1+app.s11_mesu.S11)./(1-app.s11_mesu.S11);
            plot(ax,f,real(Z),'b-','LineWidth',1.5,'DisplayName','Re(Z11) mes');
            plot(ax,f,imag(Z),'b--','LineWidth',1.5,'DisplayName','Im(Z11) mes');
        end
        if doSimu && ~isempty(app.s11_simu.S11)
            f = app.s11_simu.freq; Z = Z0*(1+app.s11_simu.S11)./(1-app.s11_simu.S11);
            plot(ax,f,real(Z),'r-','LineWidth',1.5,'DisplayName','Re(Z11) simu');
            plot(ax,f,imag(Z),'r--','LineWidth',1.5,'DisplayName','Im(Z11) simu');
        end
        xlabel(ax,'Frequence (GHz)'); ylabel(ax,'Z (Ohms)');
        title(ax,'Z11 (mesure vs simulation)'); legend(ax,'Location','best'); hold(ax,'off');

        %% TE
        ax = app.hAxTE; hold(ax,'on'); grid(ax,'on');
        ylim(ax, [0 9]);     % ← ajouter

        if doMes && ~isempty(app.ff_mesu.freq)
            [fTE,TE] = computeTE_vs_freq(app.ff_mesu);
            plot(ax,fTE,20*log10(TE),'b-','LineWidth',1.5,'DisplayName','TE mesure');
        end
        if doSimu && ~isempty(app.ff_simu.freq)
            [fTE,TE] = computeTE_vs_freq(app.ff_simu);
            plot(ax,fTE,20*log10(TE),'r--','LineWidth',1.5,'DisplayName','TE simule');
        end
        xlabel(ax,'Frequence (GHz)'); ylabel(ax,'TE (dB)');
        title(ax,'Taux Ellipticite (boresight theta=0)');
        legend(ax,'Location','best'); hold(ax,'off');

        %% S11 + TE superposes
        ax = app.hAxS11TE;
        yyaxis(ax,'left'); cla(ax); hold(ax,'on'); grid(ax,'on');ylim(ax, [-20 0]);   % ← ajouter (axe gauche = S11)

        if doMes && ~isempty(app.s11_mesu.S11)
            plot(ax,app.s11_mesu.freq,20*log10(abs(app.s11_mesu.S11)),...
                'b-','LineWidth',1.5,'DisplayName','S11 mes');
        end
        if doSimu && ~isempty(app.s11_simu.S11)
            plot(ax,app.s11_simu.freq,20*log10(abs(app.s11_simu.S11)),...
                'b--','LineWidth',1.5,'DisplayName','S11 sim');
        end
        ylabel(ax,'S11 (dB)');
        yyaxis(ax,'right');        ylim(ax, [0 9]);     

        if doMes && ~isempty(app.ff_mesu.freq)
            [fTE,TE] = computeTE_vs_freq(app.ff_mesu);
            plot(ax,fTE,20*log10(TE),'r-','LineWidth',1.5,'DisplayName','TE mes');
        end
        if doSimu && ~isempty(app.ff_simu.freq)
            [fTE,TE] = computeTE_vs_freq(app.ff_simu);
            plot(ax,fTE,20*log10(TE),'r--','LineWidth',1.5,'DisplayName','TE sim');
        end
        ylabel(ax,'TE (dB)');
        xlabel(ax,'Frequence (GHz)');
        title(ax,'S11 & TE');
        legend(ax,'Location','best'); hold(ax,'off');
    end

%% ════════════════════════════════════════════════════════════════════════
%                    TRACE  FARFIELD  (polaire + cartésien)
%% ════════════════════════════════════════════════════════════════════════
    function plotFarfield(~,~)
        if ~isfield(app,'hAxFFPolar') || ~isvalid(app.hAxFFPolar), return; end
        mode    = app.ffMode;
        qtyList = {'AR','XPD','Ephi','Etheta','Eabs','Eright','Eleft'};
        qty     = qtyList{get(app.hFFQty,'Value')};
        fReq     = str2double(get(app.hFFFreq,'String'));
        phiItems = get(app.hFFPhi,'String');
        phiIdx   = get(app.hFFPhi,'Value');
        phiReq   = str2double(phiItems{phiIdx});
        doMes   = strcmp(mode,'mes') || strcmp(mode,'vs');
        doSimu  = strcmp(mode,'sim') || strcmp(mode,'vs');

        cla(app.hAxFFPolar);        % pas de reset 
        cla(app.hAxFFCart);
        hold(app.hAxFFPolar,'on');
        hold(app.hAxFFCart,'on');  grid(app.hAxFFCart,'on');

        metricLines = {};

        %% Mesure
        if doMes && ~isempty(app.ff_mesu.freq)
            [data, theta] = extractFFData(app.ff_mesu, qty, fReq, phiReq);
            drawFFPolar(app.hAxFFPolar, data, theta, [0 0.35 0.85], [qty ' mes']);
            drawFFCart (app.hAxFFCart,  data, theta, [0 0.35 0.85], [qty ' mes']);
            m = antennaMetrics(data, theta);
            metricLines{end+1} = formatMetrics('MES', m);
        end

        %% Simulation
        if doSimu && ~isempty(app.ff_simu.freq)
            [data, theta] = extractFFData(app.ff_simu, qty, fReq, phiReq);
            drawFFPolar(app.hAxFFPolar, data, theta, [0.85 0.15 0.10], [qty ' sim']);
            drawFFCart (app.hAxFFCart,  data, theta, [0.85 0.15 0.10], [qty ' sim']);
            m = antennaMetrics(data, theta);
            metricLines{end+1} = formatMetrics('SIM', m);
        end

        %% Finaliser le polaire
        app.hAxFFPolar.ThetaZeroLocation = 'top';
        app.hAxFFPolar.ThetaDir          = 'clockwise';
        app.hAxFFPolar.ThetaLim          = [0 360];
        app.hAxFFPolar.RLim              = [0 40];
        app.hAxFFPolar.RTick             = [0 10 20 30 40];
        app.hAxFFPolar.RTickLabel        = {'-40','-30','-20','-10','0'};
        app.hAxFFPolar.FontSize          = 8;
        title(app.hAxFFPolar, ...
            sprintf('%s (dB norm.) – \\phi=%.0f°  f=%.3f GHz', qty, phiReq, fReq), ...
            'FontSize',9);
        legend(app.hAxFFPolar,'Location','northeast','FontSize',7);
        hold(app.hAxFFPolar,'off');

        %% Finaliser le cartésien
        xlabel(app.hAxFFCart,'Theta (deg)');
        ylabel(app.hAxFFCart,'Amplitude (dBi)');
        title(app.hAxFFCart, ...
            sprintf('%s (dBi) – \\phi=%.0f°  f=%.3f GHz', qty, phiReq, fReq), ...
            'FontSize',9);
        legend(app.hAxFFCart,'Location','best','FontSize',8);
        hold(app.hAxFFCart,'off');

        %% Métriques
        if isfield(app,'hFFMetrics') && isvalid(app.hFFMetrics)
            set(app.hFFMetrics,'String', strjoin(metricLines, newline));
        end
    end

    %% ── Formatage texte des métriques 
    function s = formatMetrics(lbl, m)
        s = sprintf(['%s  ###)      Main : %.2f dBi @ %.1f°   '...
            'Back : %.2f dBi @ %.1f°   '...
            'HPBW : %.1f°   FNBW : %.1f°   '...
            'SLL : %.1f dB   F/B : %.1f dB'],...
            lbl,...
            m.main_val, m.main_ang,...
            m.back_val, m.back_ang,...
            m.hpbw, m.fnbw,...
            m.sll,  m.fb);
    end

    %% ── Extraction des données 1D, dans un plan phi donné
    function [data1D, theta] = extractFFData(ff, qty, fReq, phiReq)
    [~,iF] = min(abs(ff.freq - fReq));

    Eth_all = squeeze(ff.Etheta(iF,:,:));
    Eph_all = squeeze(ff.Ephi  (iF,:,:));
    if size(Eth_all,2)==1, Eth_all=Eth_all(:); Eph_all=Eph_all(:); end

    phi360 = mod(ff.phi, 360);

    if max(ff.theta) > 181
        %% Cas A : simu theta ∈ [0°,360°], phi ∈ [0°,180°]
        %%         coupe directe + remappage → [-180°,+180°]
        [~,iP] = min(abs(phi360 - mod(phiReq,360)));
        theta  = ff.theta;
        EthC   = Eth_all(:,iP);
        EphC   = Eph_all(:,iP);
        theta(theta > 180) = theta(theta > 180) - 360;
        [theta, iSort] = sort(theta);
        EthC = EthC(iSort);
        EphC = EphC(iSort);

    elseif min(ff.theta) < -1
        %% Cas B : mesure theta ∈ [-180°,+180°]
        %%         grand cercle déjà complet, coupe directe
        [~,iP] = min(abs(phi360 - mod(phiReq,360)));
        theta  = ff.theta;
        EthC   = Eth_all(:,iP);
        EphC   = Eph_all(:,iP);

    else
        %% Cas C : simu theta ∈ [0°,180°], phi ∈ [0°,180°]
        %%         reconstruction du grand cercle :
        %%           theta ≥ 0  → phi demandé
        %%           theta < 0  → phi+180°, theta renversé
        phi0   = mod(phiReq,       360);
        phi180 = mod(phiReq + 180, 360);
        [~,iP0]   = min(abs(phi360 - phi0));
        [~,iP180] = min(abs(phi360 - phi180));

        th_pos   = ff.theta;
        EthC_pos = Eth_all(:, iP0);
        EphC_pos = Eph_all(:, iP0);
        EthC_neg = flipud(Eth_all(:, iP180));
        EphC_neg = flipud(Eph_all(:, iP180));
        th_neg   = -flipud(th_pos);

        % Supprimer le doublon à theta=0
        theta = [th_neg(1:end-1); th_pos];
        EthC  = [EthC_neg(1:end-1); EthC_pos];
        EphC  = [EphC_neg(1:end-1); EphC_pos];
    end

    %% Composantes circulaires (calculées dans le repère local de chaque point)
    Er = (EthC - 1j*EphC) / sqrt(2);
    El = (EthC + 1j*EphC) / sqrt(2);

    switch qty
        case 'Ephi',   data1D = abs(EphC);
        case 'Etheta', data1D = abs(EthC);
        case 'Eabs',   data1D = sqrt(abs(EthC).^2 + abs(EphC).^2);
        case 'Eright', data1D = abs(Er);
        case 'Eleft',  data1D = abs(El);
        case 'AR'
            mR = abs(Er); mL = abs(El);
            den = abs(mR-mL);
            den(den < 1e-12*(mR+mL+1e-30)) = 1e-12;
            data1D = (mR+mL) ./ den;
        case 'XPD'
            mR = abs(Er); mL = abs(El);
            mL(mL < 1e-12) = 1e-12;
            data1D = mR ./ mL;
    end
end
    %% ── Polaire : r = dBnorm+40, RLim=[0,40] ────────────────────────────
    function drawFFPolar(ax, data, theta, col, lbl)
        dB     = 20 * log10(max(abs(data(:)), 1e-20));
        dBnorm = dB - max(dB);           % max normalisé = 0 dB
        r      = max(dBnorm, -40) + 40;  % r ∈ [0, 40]
        th_r   = theta(:) * pi / 180;
        polarplot(ax, th_r, r(:), 'Color',col, 'LineWidth',2, 'DisplayName',lbl);
    end

    %% ── Cartésien : dBi absolu 
    function drawFFCart(ax, data, theta, col, lbl)
        dB = 20 * log10(max(abs(data(:)), 1e-20));
        plot(ax, theta(:), dB(:), 'Color',col, 'LineWidth',2, 'DisplayName',lbl);
    end

    %% ── Métriques antenne complètes ─────────────────────────────────────
    function m = antennaMetrics(data, theta)
        theta  = theta(:);
        dB     = 20 * log10(max(abs(data(:)), 1e-20));
        dBnorm = dB - max(dB);   % max = 0 dB
        N      = numel(theta);

        %% Lobe principal
        [m.main_val, idx_main] = max(dB);
        m.main_ang = theta(idx_main);

        %% Limites du lobe principal à -3 dB
        left3  = idx_main;
        right3 = idx_main;
        while left3  > 1 && dBnorm(left3-1)  > -3, left3  = left3-1;  end
        while right3 < N && dBnorm(right3+1) > -3, right3 = right3+1; end

        % HPBW en interpolant aux -3 dB exacts pour éviter HPBW=0
        ang_L = theta(left3);
        ang_R = theta(right3);
        % Interpolation linéaire côté gauche
        if left3 > 1
            t = (dBnorm(left3) - (-3)) / (dBnorm(left3) - dBnorm(left3-1) + 1e-30);
            t = max(0, min(1, t));
            ang_L = theta(left3) - t*(theta(left3)-theta(left3-1));
        end
        % Interpolation linéaire côté droit
        if right3 < N
            t = (dBnorm(right3) - (-3)) / (dBnorm(right3) - dBnorm(right3+1) + 1e-30);
            t = max(0, min(1, t));
            ang_R = theta(right3) + t*(theta(right3+1)-theta(right3));
        end
        m.hpbw = max(ang_R - ang_L, abs(theta(2)-theta(1)));

        %% FNBW : premier null de chaque côté (descente sous -20 dB)
        thresh_fn = -20;
        leftFN  = left3;
        rightFN = right3;
        while leftFN  > 1 && dBnorm(leftFN-1)  > thresh_fn, leftFN  = leftFN-1;  end
        while rightFN < N && dBnorm(rightFN+1) > thresh_fn, rightFN = rightFN+1; end
        m.fnbw = max(theta(rightFN) - theta(leftFN), m.hpbw);

        %% SLL : maximum hors du lobe principal (zone + ou - 3 dB)
        masked        = dBnorm;
        masked(left3:right3) = -Inf;
        sll_val       = max(masked);
        m.sll         = sll_val;    

        %% Lobe arrière : maximum dans la deuxième moitié angulaire
        mid = round(N/2);
        if idx_main <= mid
            bzone = dB(mid+1:end);  tz = theta(mid+1:end);
        else
            bzone = dB(1:mid);      tz = theta(1:mid);
        end
        if ~isempty(bzone)
            [m.back_val, ib] = max(bzone);
            m.back_ang = tz(ib);
        else
            m.back_val = dB(end);  m.back_ang = theta(end);
        end

        %% F/B
        m.fb = m.main_val - m.back_val;
    end

%% ════════════════════════════════════════════════════════════════════════
%               TRACE  GAIN / DIRECTIVITE / EFFICACITE
%% ════════════════════════════════════════════════════════════════════════
    function plotGain(~,~)
        if ~isfield(app,'hAxGain') || ~isvalid(app.hAxGain), return; end
        mode   = app.gainMode;
        inDB   = true;   % toujours en dB
        doMes  = strcmp(mode,'mes') || strcmp(mode,'vs');
        doSimu = strcmp(mode,'sim') || strcmp(mode,'vs');
        cla(app.hAxGain); hold(app.hAxGain,'on'); grid(app.hAxGain,'on');
        cla(app.hAxEff);  hold(app.hAxEff,'on');  grid(app.hAxEff,'on');
        if doSimu && ~isempty(app.ff_simu.freq)
            plotGainDS(app.ff_simu, app.s11_simu, inDB, '--', 'sim', false);
        end
        if doMes && ~isempty(app.ff_mesu.freq)
            plotGainDS(app.ff_mesu, app.s11_mesu, inDB, '-',  'mes', true);
        end
        xlabel(app.hAxGain,'Frequence (GHz)');
        ylabel(app.hAxGain,'(dBi)');
        title(app.hAxGain,'Directivite / Gain IEEE / Gain Realise');
        legend(app.hAxGain,'Location','best'); hold(app.hAxGain,'off');
        xlabel(app.hAxEff,'Frequence (GHz)'); ylabel(app.hAxEff,'Efficacite');
        title(app.hAxEff,'Efficacite rayonnee et totale');
        legend(app.hAxEff,'Location','best'); hold(app.hAxEff,'off');
    end

    function plotGainDS(ff, s11d, inDB, lst, lbl, isMeasured)
        nF   = numel(ff.freq);
        Dir  = zeros(1,nF);
        GI   = zeros(1,nF);
        GR   = zeros(1,nF);
        er   = zeros(1,nF);
        et   = zeros(1,nF);
        th_r = ff.theta * pi/180;
        ph_r = ff.phi   * pi/180;
        dth  = (th_r(end)-th_r(1)) / max(numel(th_r)-1, 1);
        dph  = tern(numel(ph_r)>1, (ph_r(end)-ph_r(1))/max(numel(ph_r)-1,1), 2*pi);
        [~,TH] = meshgrid(ph_r, th_r);

        for iF = 1:nF
            Eth  = squeeze(ff.Etheta(iF,:,:));
            Eph  = squeeze(ff.Ephi(iF,:,:));
            E2   = abs(Eth).^2 + abs(Eph).^2;
            E2mx = max(E2(:));

            %% Directivité — abs(sin) indispensable si theta ∈ [-180°,+180°]
            intE2 = sum(sum(E2 .* abs(sin(TH)))) * dth * dph;
            if intE2 < 1e-30, intE2 = 1e-30; end
            Dir(iF) = 4*pi * E2mx / intE2;

            %% Efficacité de désadaptation depuis S11
            mismatch = 1;
            if ~isempty(s11d.S11) && ~isempty(s11d.freq) && numel(s11d.freq)>1
                S_ = interp1(s11d.freq, s11d.S11, ff.freq(iF),'linear','extrap');
                mismatch = max(1 - abs(S_)^2, 1e-9);
            end

            if isMeasured
                %% MESURE : amp/pha stockent le Gain Réalisé absolu (dBi)
                %   E = 10^(A_dBi/20)  →  E² = Gain_réalisé (linéaire)
                GR(iF) = E2mx;                  % Gain réalisé max (linéaire)
                GI(iF) = E2mx / mismatch;       % Gain IEEE = GR / η_mismatch
                et(iF) = max(GR(iF)/Dir(iF), 0); % η_tot = GR/D
                er(iF) = max(GI(iF)/Dir(iF), 0); % η_rad = GI/D
            else
                %% SIMULATION : puissances FFS disponibles
                if ~isempty(ff.Prad) && numel(ff.Prad)>=iF && ff.Prad(iF)>0
                    Pr = ff.Prad(iF); Pa = ff.Pacc(iF); Ps = ff.Pstim(iF);
                    er(iF) = Pr / Pa;
                    et(iF) = Pr / Ps;
                else
                    er(iF) = 0.9;
                    et(iF) = 0.9 * mismatch;
                end
                GI(iF) = er(iF) * Dir(iF);
                GR(iF) = et(iF) * Dir(iF);
            end
        end

        %% Affichage
        if inDB
            D_  = 10*log10(max(Dir, 1e-12));
            GI_ = 10*log10(max(GI,  1e-12));
            GR_ = 10*log10(max(GR,  1e-12));
        else
            D_ = Dir; GI_ = GI; GR_ = GR;
        end
        ax = app.hAxGain;
        plot(ax, ff.freq, D_,  ['b' lst], 'LineWidth',1.5, 'DisplayName',['Directivite '  lbl]);
        plot(ax, ff.freq, GI_, ['g' lst], 'LineWidth',1.5, 'DisplayName',['Gain IEEE '    lbl]);
        plot(ax, ff.freq, GR_, ['r' lst], 'LineWidth',1.5, 'DisplayName',['Gain realise ' lbl]);
        ylim(ax, [0 10]);   

        ax2 = app.hAxEff;
        plot(ax2, ff.freq, er, ['k' lst], 'LineWidth',1.5, 'DisplayName',['eta\_rad ' lbl]);
        plot(ax2, ff.freq, et, ['r' lst], 'LineWidth',1.5, 'DisplayName',['eta\_tot ' lbl]);
    end

%% ════════════════════════════════════════════════════════════════════════
%                    CALLBACKS CHAMP Hi / 3D
%% ════════════════════════════════════════════════════════════════════════
    function loadChampHi(~,~)
        sd = fullfile(app.workingDir,'simulation');
        if ~isfolder(sd), sd = app.workingDir; end
        [f,d] = uigetfile({'*.png;*.jpg;*.bmp','Images'},...
            'Charger image champ Hi', sd);
        if f ~= 0
            img = imread(fullfile(d,f));
            imshow(img,'Parent',app.hAxHi);
            title(app.hAxHi,f);
        end
    end

    function autoLoadHi()
        sd = fullfile(app.workingDir,'simulation');
        hiFiles = [dir(fullfile(sd,'Hi.png')); dir(fullfile(sd,'Hi.PNG'));...
                   dir(fullfile(sd,'hi.png'))];
        if ~isempty(hiFiles)
            img = imread(fullfile(sd, hiFiles(1).name));
            imshow(img,'Parent',app.hAxHi);
            title(app.hAxHi, hiFiles(1).name);
        end
    end

    function browseWorkingDir(~,~)
        d = uigetdir(app.workingDir,'Selectionner le repertoire de travail');
        if d ~= 0
            app.workingDir = d;
            set(app.hWDEdit,'String',d);
        end
    end

%% ════════════════════════════════════════════════════════════════════════
%               LECTURE DES FICHIERS
%% ════════════════════════════════════════════════════════════════════════

    %% ── Lecture S11 texte CST ────────────────────────────────────────────
    function [freq, S11c] = readS11txt(filepath)
        freq = []; S11c = [];
        try
            fid = fopen(filepath,'r');
            data = [];
            while ~feof(fid)
                l = strtrim(fgetl(fid));
                if ~ischar(l) || isempty(l), continue; end
                % Ignorer commentaires (les lignes qui commencent par ; % ! // #)
                if l(1)=='!' || l(1)=='#' || l(1)==';' || l(1)=='%', continue; end
                if length(l)>1 && strcmp(l(1:2),'//'), continue; end
                nums = str2num(l); %#ok<ST2NM>
                if numel(nums) >= 3
                    data(end+1,:) = nums(1:3); %#ok<AGROW>
                end
            end
            fclose(fid);
            if isempty(data), return; end
            fRaw = data(:,1);
            c2   = data(:,2);
            c3   = data(:,3);

            % Convertir freq en GHz si nécessaire
            freq = tern(max(fRaw)>1e6, fRaw/1e9, fRaw);

            %% Détection du format
            % Si |c3| > 2 pour certains points alors c3 contient des angles (degrés)
            % En RI, Im(S11) ∈ [-1,1] pour un dispositif passif
            isAngleFormat = max(abs(c3)) > 2;
            if isAngleFormat
                if max(c2) > 2 || min(c2) < -2
                    % dB / degrés (export CST par défaut)
                    S11c = 10.^(c2/20) .* exp(1j*c3*pi/180);
                else
                    % Magnitude linéaire [0 à 1] / degrés
                    S11c = c2 .* exp(1j*c3*pi/180);
                end
            else
                % RI
                S11c = complex(c2, c3);
            end
        catch; end
    end

    %% ── Lecture Touchstone .S2P via RF Toolbox ───────────────────────────
    function [freq, S11c] = readS2P(filepath)
        freq = []; S11c = [];
        try
            S    = sparameters(filepath);
            freq = S.Frequencies / 1e9;          
            S11c = squeeze(S.Parameters(1,1,:));  
        catch ME
            warning('readS2P (RF Toolbox) : %s', ME.message);
        end
    end

    %% ── Lecture dossier Farfield .ffs ────────────────────────────────────
    function ff = readFFSFolder(ffDir, wb)
        ffsFiles = dir(fullfile(ffDir,'*.ffs'));
        nF = numel(ffsFiles);
        freqVec = zeros(nF,1);
        PradV   = zeros(nF,1);
        PaccV   = zeros(nF,1);
        PstimV  = zeros(nF,1);
        EthCell = cell(nF,1);
        EphCell = cell(nF,1);
        thRef   = []; phRef = [];

        for k = 1:nF
            if nargin>=2 && isvalid(wb)
                waitbar(0.5 + 0.5*k/nF, wb, ...
                    sprintf('FFS %d/%d : %s', k, nF, ffsFiles(k).name));
            end
            [fk,thk,phk,Ethk,Ephk,Prk,Pak,Psk] = ...
                readOneFFS(fullfile(ffDir, ffsFiles(k).name));
            freqVec(k) = fk;
            PradV(k)   = Prk;
            PaccV(k)   = Pak;
            PstimV(k)  = Psk;
            EthCell{k} = Ethk;
            EphCell{k} = Ephk;
            if isempty(thRef) && ~isempty(thk)
                thRef = thk; phRef = phk;
            end
        end

        % Assemblage
        [freqVec, idx] = sort(freqVec);
        nTH = numel(thRef); nPH = numel(phRef);
        Eth3 = zeros(nF, nTH, nPH);
        Eph3 = zeros(nF, nTH, nPH);
        for k = 1:nF
            ii = idx(k);
            if ~isempty(EthCell{ii})
                Eth3(k,:,:) = EthCell{ii};
                Eph3(k,:,:) = EphCell{ii};
            end
        end
        ff.freq   = freqVec;
        ff.theta  = thRef(:);
        ff.phi    = phRef(:);
        ff.Etheta = Eth3;
        ff.Ephi   = Eph3;
        ff.Prad   = PradV(idx);
        ff.Pacc   = PaccV(idx);
        ff.Pstim  = PstimV(idx);
    end

    function [freq,theta,phi,Etheta,Ephi,Prad,Pacc,Pstim] = readOneFFS(filepath)
        % Lecture d'un fichier CST Farfield Source (.ffs)
        freq=0; theta=[]; phi=[]; Etheta=[]; Ephi=[];
        Prad=0; Pacc=0; Pstim=0;
        nPhi=0; nTheta=0; firstDataLine='';
        try
            fid = fopen(filepath,'r');
            powerLines = {};
            while ~feof(fid)
                l = strtrim(fgetl(fid));
                if ~ischar(l), continue; end
                if contains(l,'Radiated/Accepted/Stimulated')
                    for ii=1:4
                        pl = strtrim(fgetl(fid));
                        if ischar(pl), powerLines{end+1} = pl; end %#ok<AGROW>
                    end
                    if numel(powerLines)>=4
                        Prad  = str2double(powerLines{end-3});
                        Pacc  = str2double(powerLines{end-2});
                        Pstim = str2double(powerLines{end-1});
                        freq  = str2double(powerLines{end})/1e9;
                    end
                elseif contains(l,'Total #phi samples')
                    nl = strtrim(fgetl(fid));
                    n  = sscanf(nl,'%f');
                    if numel(n)>=2, nPhi=n(1); nTheta=n(2); end
                elseif nPhi>0 && nTheta>0 && ~isempty(l) && l(1)~='/'
                    firstDataLine = l;
                    break;
                end
            end
            if nPhi>0 && nTheta>0
                % Construire raw : première ligne + reste via fscanf
                nRows = nPhi * nTheta;
                row1 = sscanf(firstDataLine,'%f',6)';
                if numel(row1)==6
                    rest = fscanf(fid,'%f',[6, nRows-1])';
                    raw  = [row1; rest];
                else
                    raw = fscanf(fid,'%f',[6, nRows])';
                end
                fclose(fid);
                if size(raw,1) >= nRows
                    raw = raw(1:nRows,:);
                    phiArr   = raw(:,1); thetaArr = raw(:,2);
                    phi      = unique(phiArr,'sorted');
                    theta    = unique(thetaArr,'sorted');
                    nP = numel(phi); nT = numel(theta);
                    Etheta = zeros(nT,nP);
                    Ephi   = zeros(nT,nP);
                    for r = 1:nRows
                        iP = find(abs(phi   - phiArr(r))   < 1e-6, 1);
                        iT = find(abs(theta - thetaArr(r)) < 1e-6, 1);
                        if ~isempty(iP)&&~isempty(iT)
                            Etheta(iT,iP) = complex(raw(r,3),raw(r,4));
                            Ephi(iT,iP)   = complex(raw(r,5),raw(r,6));
                        end
                    end
                end
            else
                fclose(fid);
            end
        catch ME
            try fclose(fid); catch; end
            warning('readOneFFS : %s',ME.message);
        end
    end

    %% ── Lecture dossiers Ehoriz / Evert ─────────────────────────────────
    function ff = readAmpPhaFolders(horizDir, vertDir, wb)
        % Ehoriz vers Ephi,  Evert vers Etheta
        ampH = dir(fullfile(horizDir,'*.amp'));
        ff.freq=[]; ff.theta=[]; ff.phi=[];
        ff.Etheta=[]; ff.Ephi=[]; ff.Prad=[]; ff.Pacc=[]; ff.Pstim=[];

        % Collecter freq et phi depuis les headers
        allFreq=[]; allPhi=[];
        for k=1:numel(ampH)
            [fv,pv] = parseAmpHeader(fullfile(horizDir,ampH(k).name));
            allFreq(end+1)=fv; allPhi(end+1)=pv; %#ok<AGROW>
        end
        fList = unique(allFreq);
        pList = unique(allPhi);
        nF=numel(fList); nPH=numel(pList);

        % Lire theta depuis le premier fichier
        [~,~,th0,~] = readAmpFile(fullfile(horizDir,ampH(1).name));
        thList = th0(:);
        nTH = numel(thList);

        Eth = zeros(nF,nTH,nPH);
        Eph = zeros(nF,nTH,nPH);

        % Ehoriz vers Ephi
        for k=1:numel(ampH)
            fp = fullfile(horizDir,ampH(k).name);
            pp = fullfile(horizDir,strrep(ampH(k).name,'.amp','.pha'));
            [fv,pv,thk,ampK] = readAmpFile(fp);
            phK = zeros(size(ampK));
            if exist(pp,'file'), [~,~,~,phK] = readAmpFile(pp); end
            iF  = find(fList==fv,1); iP = find(pList==pv,1);
            if isempty(iF)||isempty(iP), continue; end
            aI = interp1(thk,ampK,thList,'linear',0);
            pI = interp1(thk,phK,thList,'linear',0);
            Eph(iF,:,iP) = 10.^(aI/20).*exp(1j*pI*pi/180);
            if nargin>=3&&isvalid(wb)
                waitbar(0.35+0.3*k/numel(ampH),wb,...
                    sprintf('Ehoriz %d/%d',k,numel(ampH)));
            end
        end

        % Evert vers  Etheta
        ampV = dir(fullfile(vertDir,'*.amp'));
        for k=1:numel(ampV)
            fp = fullfile(vertDir,ampV(k).name);
            pp = fullfile(vertDir,strrep(ampV(k).name,'.amp','.pha'));
            [fv,pv,thk,ampK] = readAmpFile(fp);
            phK = zeros(size(ampK));
            if exist(pp,'file'), [~,~,~,phK] = readAmpFile(pp); end
            iF  = find(fList==fv,1); iP = find(pList==pv,1);
            if isempty(iF)||isempty(iP), continue; end
            aI = interp1(thk,ampK,thList,'linear',0);
            pI = interp1(thk,phK,thList,'linear',0);
            Eth(iF,:,iP) = 10.^(aI/20).*exp(1j*pI*pi/180);
            if nargin>=3&&isvalid(wb)
                waitbar(0.65+0.3*k/numel(ampV),wb,...
                    sprintf('Evert %d/%d',k,numel(ampV)));
            end
        end

        ff.freq   = fList(:);
        ff.theta  = thList;
        ff.phi    = pList(:);
        ff.Etheta = Eth;
        ff.Ephi   = Eph;
        ff.Prad   = zeros(nF,1);
        ff.Pacc   = zeros(nF,1);
        ff.Pstim  = zeros(nF,1);
    end

    function [freqV, phiV] = parseAmpHeader(filepath)
        freqV=0; phiV=0;
        try
            fid = fopen(filepath,'r');
            while ~feof(fid)
                l = strtrim(fgetl(fid));
                if ~ischar(l), continue; end
                if startsWith(l,'FreqValue=')
                    freqV = str2double(l(11:end));
                elseif startsWith(l,'StepPosition=')
                    phiV  = str2double(l(14:end));
                end
                if startsWith(l,'Data#'), break; end
            end
            fclose(fid);
        catch; end
    end

    function [freqV, phiV, theta, vals] = readAmpFile(filepath)
        freqV=0; phiV=0; theta=[]; vals=[];
        try
            fid = fopen(filepath,'r');
            data=[]; inData=false;
            while ~feof(fid)
                l = strtrim(fgetl(fid));
                if ~ischar(l), continue; end
                if startsWith(l,'FreqValue=')
                    freqV = str2double(l(11:end));
                elseif startsWith(l,'StepPosition=')
                    phiV  = str2double(l(14:end));
                elseif startsWith(l,'Data#')
                    inData = true;
                elseif inData
                    n = sscanf(l,'%f');
                    if numel(n)>=2, data(end+1,:)=n(1:2); end %#ok<AGROW>
                end
            end
            fclose(fid);
            if ~isempty(data), theta=data(:,1); vals=data(:,2); end
        catch; end
    end

%% ════════════════════════════════════════════════════════════════════════
%               CALCULS DERIVES
%% ════════════════════════════════════════════════════════════════════════
    function [fTE, TE] = computeTE_vs_freq(ff)
        nF  = numel(ff.freq);
        fTE = ff.freq;
        TE  = ones(nF,1);
        [~,iTH] = min(abs(ff.theta));  % theta le plus proche de 0
        for iF = 1:nF
            Eth = squeeze(ff.Etheta(iF,iTH,:));
            Eph = squeeze(ff.Ephi(iF,iTH,:));
            Er  = (Eth - 1j*Eph)/sqrt(2);
            El  = (Eth + 1j*Eph)/sqrt(2);
            mR  = mean(abs(Er)); mL = mean(abs(El));
            den = abs(mR-mL);
            if den < 1e-12*(mR+mL+1e-30), den = 1e-12*(mR+mL+1e-30); end
            TE(iF) = (mR+mL)/den;
        end
    end

%% ════════════════════════════════════════════════════════════════════════
%               UTILITAIRES
%% ════════════════════════════════════════════════════════════════════════
    function cfgAx(ax,xl,yl,ttl)
        xlabel(ax,xl); ylabel(ax,yl); title(ax,ttl);
        grid(ax,'on'); box(ax,'on'); set(ax,'FontSize',9);
    end

    function h = mkLbl(parent,str,x,y,w,hh)
        h = uicontrol('Parent',parent,'Style','text','String',str,...
            'BackgroundColor',C_WHITE,'ForegroundColor',C_BLACK,...
            'FontSize',9,'FontWeight','bold',...
            'Units','normalized','Position',[x y w hh]);
    end

    function h = mkPop(parent,items,x,y,w,hh)
        h = uicontrol('Parent',parent,'Style','popupmenu','String',items,...
            'FontSize',9,'Units','normalized','Position',[x y w hh]);
    end

    function v = tern(cond,a,b)
        if cond; v=a; else; v=b; end
    end

end 
