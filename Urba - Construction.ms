/*
#######################################################################################################################
	Christophe Pages (http://www.c-pages.fr) 	
##########################################################################################################################
	
	URBA
	Générateur de ville
	
##########################################################################################################################
	
	La structure d'édition de construction architecturale.
	
##########################################################################################################################

	todo:
	
##########################################################################################################################
	changelog:
	*v0.1 - [27/07/2017] -----------------------------------------------------------------------------
	- Mise en place globale 
	
########################################################################################################################*/

---- la structure de construction	---------------------------------------------------------------------------------------------
struct str_urba_construction (
	
	------------ DEBUG	----------------------------------------------------------------------------------
	m_debug = true,
	m_dbgPrefix ="urba - construction",
	fn debug 	_txt  var:	 param:    =(
		if m_debug do ::debuger 	_txt  	var:var	 param:param	prefix:m_dbgPrefix
	),
	
	
	
	
	--- DETAILS	----
	fn	tablette		_node	_facesBase = (
		
		---- selection des faces	----
		polyop.setFaceSelection _node	_facesBase		
		
		---- matID  tablette	----
		_node.EditablePoly.setMaterialIndex 		matID.tablette	 	1
		
		---- extrusion  des tablettes	----
		_node.extrusionType 				= 0
		_node.faceExtrudeHeight 		= prefs.ht_tablette
		_node.EditablePoly.buttonOp 	#Extrude
		
		-- listes des trucs a supprimer	(points et arretes en trop )	----
		listeArretesAVirer 	= polyop.getEdgesUsingFace	_node	( ( polyop.getFaceSelection  _node ) as array )
		listePointsAVirer 	= polyop.getVertsUsingFace  	_node	( ( polyop.getFaceSelection  _node ) as array )
		
		---- Extrusion du débord des tablettes 	----
		outils.etendreSelecFaces		_node		( ( polyop.getFaceSelection  _node ) as array )
		_node.faceExtrudeHeight = prefs.ep_tablette
		_node.extrusionType = 1
		_node.EditablePoly.buttonOp #Extrude
		
	),
	fn cadre 	_node	_facesBase = (
		
		---- selection des faces	----
		polyop.setFaceSelection _node	_facesBase		
		
		---- matID  menuiseries	----
		_node.EditablePoly.setMaterialIndex 		matID.menuiseries	 	1
		
		---- Inset de la hauteur des menuiseries	----
		_node.insetType = 1
		_node.insetAmount = prefs.larg_cadreFenetre
		_node.EditablePoly.buttonOp 		#Inset
		
		---- Extusion des menuiserie	----
		_node.extrusionType 				= 0
		_node.faceExtrudeHeight 		= -prefs.ep_cadreFenetre
		_node.EditablePoly.buttonOp	#Extrude 
		
		---- matID  vitrage	----
		_node.EditablePoly.setMaterialIndex 		matID.verre	 	1
		
	),
	
	--- NIVEAUX ----
	fn etage 	_node	_faces	= (
		undo "construction : étage" on (
			with redraw off (
				
				---- Selection des faces (deja selectionnées dans la version de base)	----
				polyop.setFaceSelection  _node 	_faces
				
				---- extrusion de la hauteur sous plafond----
				_node.extrusionType = 0
				_node.faceExtrudeHeight = prefs.ht_etage
				_node.EditablePoly.buttonOp #Extrude
				
				---- le nom de la selection des "facades"----
				_faceSelectionTmp 	= (  polyop.getFaceSelection  _node  ) as array 
				outils.etendreSelecFaces		_node 	_faceSelectionTmp
				_facesFacades 			= 	(  polyop.getFaceSelection  _node  ) as array 
				outils.grouperFaces 	_node	_facesFacades	"const_facades" 	
				polyop.setFaceSelection  _node _faceSelectionTmp
				
				---- extrusion de l'épaisseur de la dalle----
				_node.faceExtrudeHeight = prefs.ep_dalle
				_node.EditablePoly.buttonOp #Extrude
				
				---- le nom de la selection des "dalles"----
				_faceSelectionTmp 	= (  polyop.getFaceSelection  _node  ) as array 
				outils.etendreSelecFaces		_node 	_faceSelectionTmp
				_facesFacades 			= 	(  polyop.getFaceSelection  _node  ) as array 
				outils.grouperFaces 	_node	_facesFacades	"const_dalles" 	
				polyop.setFaceSelection  _node _faceSelectionTmp
				
			) -- fin redraw off
			redrawViews()
		)	-- fin undo
	),
	fn diviser	_ratio 	_node	_faces	= (			
		undo "construction : Diviser" on (
			with redraw off (
				
				---- Selection des faces (deja selectionnées dans la version de base)	----
				polyop.setFaceSelection  _node 	_faces
				
				local _facesFinales = #()
				
				--- Decoupage des faces	----
				polyop.setEdgeSelection  _node #()					
				for face in  _faces do (
					
					local centreFace 			= 	outils.centreDeLaFace		_node	face	
					local largeurFace			= outils.largeurFace	_node	face
					local normalFace 			= ( polyop.getFaceNormal _node face ) 
					local normalFaceRotZ	= normalFace * rotateZMatrix 90 
					local origine					= centreFace + normalFaceRotZ * ( -largeurFace/2 )
					local origineSlice 			= origine - _node.pos						
					local translation			= normalFaceRotZ * ( largeurFace / _ratio )
					
					---- Selection des faces (deja selectionnées dans la version de base)	----
					polyop.setFaceSelection  _node 	#(face)
					
					for i = 1 to ( _ratio - 1) do (
						
							---- Slice debut fenetre ----
							_node.slice 	normalFaceRotZ 	( origineSlice + translation )  	flaggedFacesOnly:true
							
							---- le nom de la selection des "facades"----
							_faceSelectionTmp 	= (  polyop.getFaceSelection  _node  ) as array
							outils.grouperFaces 	_node	_faceSelectionTmp	"const_facades"
							for faceFinale in _faceSelectionTmp do
								appendIfUnique _facesFinales faceFinale
							
							---- Actualiser translation	----
							translation += translation
						
					) -- fin for i
				) -- fin for face
				
				---- Selection des faces 	----
				polyop.setFaceSelection  _node 	_facesFinales
				
			) -- fin redraw off
			redrawViews() 
		)	-- fin undo
	),
	
	--- TOITURES ----		
	fn accrotere	_node	_faces	= (
		undo "construction : accrotere" on (
			with redraw off (
				
				---- Selection des faces (deja selectionnées dans la version de base)	----
				polyop.setFaceSelection  _node 	_faces
				
				---- MatID mur	----
				_node.EditablePoly.setMaterialIndex 		matID.mur	 	1
				
				---- Inset de l'épaisseur du mur ----
				_node.insetType = 0
				_node.insetAmount = prefs.ep_mur
				_node.EditablePoly.buttonOp 		#Inset
				
				---- Extusion de l'accrotere	----
				outils.etendreSelecFaces 		_node 	( ( polyop.getFaceSelection  _node ) as array )
				_node.extrusionType 				= 0
				_node.faceExtrudeHeight 		= prefs.ht_accrotere
				_node.EditablePoly.buttonOp	#Extrude
				
				---- Copie des faces pour creer la base de la couvertine 	----
				_facesCouvertine = _node.EditablePoly.getSelection #Face
				_node.EditablePoly.detachToElement 	#Face 		keepOriginal:on
				
				---- MatID couvertine	----
				_node.EditablePoly.setMaterialIndex 		matID.couvertine	 	1
				
				---- Epaisseur de la couvertine 	----
				_node.faceExtrudeHeight = prefs.ht_couvertine
				_node.EditablePoly.buttonOp #Extrude
				
				-- listes des trucs a supprimer	(points et arretes en trop )	----
				listeArretesAVirer 	= polyop.getEdgesUsingFace	_node	( ( polyop.getFaceSelection  _node ) as array )
				listePointsAVirer 	= polyop.getVertsUsingFace  	_node	( ( polyop.getFaceSelection  _node ) as array )
				
				---- Extrusion du débord de la couvertine 	----
				outils.etendreSelecFaces		_node		( ( polyop.getFaceSelection  _node ) as array )
				_node.faceExtrudeHeight = prefs.ht_couvertine
				_node.extrusionType = 1
				_node.EditablePoly.buttonOp #Extrude
				
				---- Suppression des trucs (points et arretes en trop )	----
				_node.EditablePoly.SetSelection #Edge 		listeArretesAVirer
				_node.EditablePoly.SetSelection #Vertex 	listePointsAVirer
				subobjectLevel = 2
				_node.EditablePoly.Remove ()
				subobjectLevel = 1
				_node.EditablePoly.Remove ()
				
				---- Deselection des faces ----
				subobjectLevel = 4
				_node.EditablePoly.SetSelection #Face #{}
				
				
			) -- fin redraw off
			redrawViews()
		)	-- fin undo
	),
	fn pansDeux 		_node	_faces	= (
		undo "construction : 2 pans" on (
			with redraw off (
				
				---- Selection des faces (deja selectionnées dans la version de base)	----
				polyop.setFaceSelection  _node 	_faces
				
				---- declarations ----					
				local 	_listeArretes = polyop.getEdgesUsingFace 	_node	( polyop.getFaceSelection  _node ) 
				
				--- si on a un rectangle ----
				if ( _listeArretes as array ).count == 4 do (
					
					---- 	CREATION DU DEBORD	----
					-- Selection des faces à extruder --
					outils.etendreSelecFaces		_node 	_faces
					_facesDalles 			= ( polyop.getFaceSelection  _node ) as array
					_facesPourDebords = outils.facesLesPlusGrandes	_node	_facesDalles
					polyop.setFaceSelection  _node	_facesPourDebords
					
					_faceLaPlusPetite 	=	( outils.facesLesPlusPetites 	_node 	_facesDalles)[1]
					_hauteurFaitage 	= ( outils.largeurFace	_node	_faceLaPlusPetite ) / 2
					
					-- Extrusion du debord --					
					_node.extrusionType 				= 1
					_node.faceExtrudeHeight 		= prefs.lrg_debord
					_node.EditablePoly.buttonOp	#Extrude
					
					
					---- CREATION DU FAITAGE ----
					-- selection des faces pour le toit --
					polyop.setFaceSelection  _node	_faces
					
					-- Selection des arretes pour connection --
					subobjectLevel = 2
					_arretesPourConnect	=	outils.arretesLesPlusPetites		_node   _listeArretes
					polyop.setEdgeSelection  _node 	_arretesPourConnect
					
					-- Connection des arretes pour creation faitage	--
					_node.connectEdgeSegments = 1
					_node.connectEdgePinch = 0
					_node.connectEdgeSlide = 0
					_node.EditablePoly.ConnectEdges ()
					
					--- hauteur du faitage --
					_hauteurToiture =  _hauteurFaitage
					move 	_node.selectedEdges [0,0, _hauteurToiture ]
					
					---- CREATION DU TOIT ----
					-- smothing group des faces du toit ---
					_node.EditablePoly.ConvertSelection #Edge #Face
					subobjectLevel = 4
					_node.EditablePoly.autosmooth ()
					
					-- extrusion de la hauteur du toit --
					_node.extrusionType 				= 1
					_node.faceExtrudeHeight 		= prefs.ht_toiture
					_node.EditablePoly.buttonOp #Extrude
					
					-- Selection epaisseur Du toit --
					outils.etendreSelecFaces		_node 	( polyop.getFaceSelection  _node )
					
					-- extrusion de la epaisseur du toit --
					_node.extrusionType 				= 1
					_node.faceExtrudeHeight 		= prefs.ep_toiture
					_node.EditablePoly.buttonOp #Extrude
					
				) ---- fin de si on a un rectangle
				
				
			) -- fin redraw off
			redrawViews()
		)	-- fin undo
	),
	fn pansTrois 	_node	_faces	= (
		format "pansTrois\n"
		undo "construction : 3 pans" on (
			with redraw off (
				
				---- Selection des faces (deja selectionnées dans la version de base)	----
				polyop.setFaceSelection  _node 	_faces
									
			) -- fin redraw off
			redrawViews()
		)	-- fin undo
		
	),
	fn pansQuatre 	_node	_faces	= (
		format "pansQuatre\n"
		undo "construction : 4 pans" on (
			with redraw off (
				
				---- Selection des faces (deja selectionnées dans la version de base)	----
				polyop.setFaceSelection  _node 	_faces
				
			) -- fin redraw off
			redrawViews()
		)	-- fin undo
		
	),
	
	---- OUVERTURES ----
	fn baies 	_node	_faces	= (
		
		undo "construction : bais" on (
			with redraw off (
				
				---- Selection des faces (deja selectionnées dans la version de base)	----
				polyop.setFaceSelection  _node 	_faces
				
				--- declarations	----
				local _facesBais			= #()
				local _facesSelection 	= _faces
				
				---- MatID mur	----
				_node.EditablePoly.setMaterialIndex 		matID.mur	 	1
				
				---- DECOUPES HORIZONTALES	----
				polyop.setEdgeSelection  _node #()					
				for face in  _facesSelection do (
					
					local hauteurFace 		= outils.hauteurFace 	_node	face
					local largeurFace		= outils.largeurFace	_node	face
					local hauteurFaceMin	= prefs.ht_fenetre
					local largeurFaceMin	= prefs.larg_Fenetre + prefs.ep_mur
					local Zmin 				= outils.ZMinFace 		_node 	#(face)						
					local hauteurLinteau 	= if prefs.ht_fenetre > hauteurFace then hauteurFace else prefs.ht_fenetre
					
					-- Selection de la face a tailler --
					polyop.setFaceSelection  	_node 	#(face)
					
					---- Découpe de l'allège	----
					_node.slice [0,0,1] [0,0,Zmin + prefs.ht_allege ] 	flaggedFacesOnly:true
					
					if hauteurLinteau != hauteurFace then (
						---- Découpe du linteau	----
						_node.slice [0,0,1] [0,0,Zmin + hauteurLinteau ] 	flaggedFacesOnly:true
						
						---- DECOUPES VERTICALES	----
						-- Selection de la face à découper --
						facesTmp 		= 	polyop.getEdgeFaces		_node	( _node.GetNumEdges	() )
						nouvelleFace 	=	outils.faceLaPlusBasse 	_node 	facesTmp							
						polyop.setFaceSelection  _node		#( nouvelleFace  )
					) 
					
					local centreFace 		= 		outils.centreDeLaFace		_node	face							
					local normalFace 		= ( polyop.getFaceNormal _node face ) 
					local normalFaceRotZ= normalFace * rotateZMatrix 90 
					local largeurFace 		= outils.largeurFace 		_node 	face
					local origine				= centreFace + normalFaceRotZ * ( -largeurFace/2 + prefs.ep_mur )
					local origineSlice 		= origine - _node.pos
					local transl_fenetre	= normalFaceRotZ * prefs.larg_Fenetre
					local transl_plein		= normalFaceRotZ * prefs.esp_fenetre
					local translation		= [0,0,0]
					local nbr_fenetre 		= 0
					local nbr_fenetreMax	=	if prefs.nbr_fenetre == 0 then 1 else prefs.nbr_fenetre
					local dimensionMin 	= transl_fenetre  + normalFaceRotZ *	prefs.ep_mur
					
					
					while  length ( translation +  dimensionMin ) < largeurFace and nbr_fenetre < nbr_fenetreMax 	do (
						
						---- Slice debut fenetre ----
						_node.slice 	normalFaceRotZ 	( origineSlice + translation )  	flaggedFacesOnly:true
						
						---- Actualiser translation	----
						translation += transl_fenetre	
						
						---- Slice fin fenetre ----
						polyop.setEdgeSelection  _node		#()
						_node.slice 	normalFaceRotZ 	( origineSlice + translation ) 	flaggedFacesOnly:true
						
						----	Ajout de la face de la fenetre dans la liste pour extrusion epaisseur du mur	----
						derniereArrete 	=	(( polyop.getEdgeSelection  	_node ) as array )[1]
						if derniereArrete != undefined do (
							facesTmp 			= 	polyop.getEdgeFaces			_node		derniereArrete
							faceAAjouter 		= outils.faceLaPlusProche		_node 	facesTmp	origine
							append 	_facesBais		faceAAjouter 
						)
						---- Actualiser nombre de fenetre créées	----
						if prefs.nbr_fenetre != 0 do  nbr_fenetre += 1
						
						---- Actualiser translation	----
						translation += transl_plein
						
					)	-- fin du while --	
					
				)	-- fin du for
				
				---- Extrusion epaisseur du mur ----
				polyop.setFaceSelection  _node		_facesBais
				_node.faceExtrudeHeight 	= -prefs.ep_mur
				_node.extrusionType 			= 1
				_node.EditablePoly.buttonOp #Extrude
				
				---- le nom de la selection des faces ----
				outils.grouperFaces	_node		(( polyop.getFaceSelection  _node ) as array) 		"const_baies" 	
				
				---- retirer de groupe "facades"	----
				outils.degrouperFaces 	_node 	_facesSelection 	"const_facades" 
				
				---- MatID verre	----
				_node.EditablePoly.setMaterialIndex 		matID.verre	 	1
				
			) -- fin redraw off
			
			redrawViews() 
			
		)	-- fin undo
		
	),
	fn ventDeux 	_node	_faces	= (
		
		undo "construction : deux ventaux" on (
			with redraw off (
				
				---- Selection des faces (deja selectionnées dans la version de base)	----
				polyop.setFaceSelection  _node 	_faces
				
				--- declarations	----
				local _facesSelection 	= ( polyop.getFaceSelection  _node )
				
				
				---- creation des tablettes	----
				_facesTablettes 	= outils.facesDuDessous		_node	_faces
				tablette		_node	_facesTablettes					
				
				---- creation du cadre	---
				cadre 	_node	_faces
				_facesTmp = polyop.getFaceSelection  _node 	
				
				---- Correction de la face du cadre pour la faire sortir de la tablette ----
				_facesDuDessous 	= outils.facesDuDessous		_node	_facesTmp
				polyop.setFaceSelection  _node 	_facesDuDessous
				move _node.selectedFaces [0,0, prefs.ep_tablette ]
				
				
				---- Selection des faces pour ouvrants ----
				polyop.setFaceSelection  _node 	_facesTmp
				
				---- Division de la baie en 2	---
				diviser 2 	_node	_faces
				
				---- creation des fenetre	---
				_facesFenetres =  polyop.getFaceSelection  _node 
				cadre 	_node	_facesFenetres 
				
				
				
			) -- fin redraw off				
			redrawViews() 	 				
		)	-- fin undo
		
	),		
	fn ventDeuxAllege 	_node	_faces	= (
		format "ventDeuxAllege\n"
		undo "construction : 2 ventaux + allège" on (
			with redraw off (
				
				---- Selection des faces (deja selectionnées dans la version de base)	----
				polyop.setFaceSelection  _node 	_faces
									
			) -- fin redraw off
			redrawViews()
		)	-- fin undo
		
	),
	
	---- BALCONS/LOGGIAS -----
	fn balcon 	_node	_faces	= (
		format "balcon\n"
		undo "construction : Balcon" on (
			with redraw off (
				
				---- Selection des faces (deja selectionnées dans la version de base)	----
				polyop.setFaceSelection  _node 	_faces
									
			) -- fin redraw off
			redrawViews()
		)	-- fin undo
		
	),
	fn loggia 	_node	_faces	= (
		format "loggia\n"
		undo "construction : Loggia" on (
			with redraw off (
				
				---- Selection des faces (deja selectionnées dans la version de base)	----
				polyop.setFaceSelection  _node 	_faces
				
			) -- fin redraw off
			redrawViews()
		)	-- fin undo
		
	)
	
)