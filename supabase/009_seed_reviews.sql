-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  SEED — Avis clients Le Martin Boutique Hotel                  ║
-- ║  Source: Google (219 avis, 5.0★) + Tripadvisor (17 avis, 5.0★)║
-- ║  211 avis insérés (197 Google + 14 Tripadvisor)                ║
-- ╚══════════════════════════════════════════════════════════════════╝


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  REVIEW_STATS — Agrégats par plateforme
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT INTO review_stats (platform, total_reviews, average_rating, rating_5_count, rating_4_count, rating_3_count, rating_2_count, rating_1_count) VALUES
('google',      219, 5.0, 215, 3, 1, 0, 0),
('tripadvisor',  17, 5.0,  17, 0, 0, 0, 0);


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  REVIEWS — Tous les avis clients
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT INTO reviews (source, author_name, rating, review_text, original_language, is_translated, visit_type, travel_group, visited_date, sub_rating_rooms, sub_rating_service, sub_rating_location, highlights, owner_response, photo_count, posted_at) VALUES

-- ══════════════════════════════════════════════════════
-- GOOGLE REVIEWS
-- ══════════════════════════════════════════════════════

('google','Marie-Laurence Robert',5,'Une adresse à ne pas manquer, intimiste et chaleureuse. Une déco inspirante et une chambre avec une vue privilégiée sur la mer. Un petit déjeuner généreux et terriblement délicieux préparé et servi avec soin.','fr',FALSE,'vacances',NULL,'février 2026',NULL,NULL,NULL,NULL,NULL,0,'2026-02-10'),

('google','Choupys',5,'Séjour exceptionnel au Le Martin Boutique Hôtel, une véritable pépite des Caraïbes. L''hôtel est élégant et chaleureux, avec une décoration soignée jusque dans les moindres détails.','fr',FALSE,'vacances','couple','février 2026',NULL,NULL,NULL,NULL,NULL,2,'2026-02-10'),

('google','Anderson Rodrigues da Conceição',5,'Tout s''est très bien passé lors de notre voyage à Saint-Martin. Nous devons une grande partie de cette excellente expérience à Marion, qui nous a accompagnés avec beaucoup de professionnalisme dès notre première journée à l''hôtel.','fr',FALSE,NULL,NULL,'janvier 2026',NULL,NULL,NULL,NULL,NULL,0,'2026-02-03'),

('google','Camille Elofir',5,'Expérience incroyable dans le très bel hôtel ! Marion, Emmanuel, Idalia et toute l''équipe sont aux petits soins. Tout est fait pour qu''on se détende et qu''on profite !','fr',FALSE,NULL,NULL,'février 2026',NULL,NULL,NULL,NULL,NULL,0,'2026-02-24'),

('google','Martin Lessard',5,'Nous avons passé un séjour absolument fabuleux au Le Martin Boutique Hotel la semaine dernière sur l''île de Saint-Martin. Dès notre arrivée, nous avons été charmés par l''accueil chaleureux et le souci du détail qui rendent cet endroit si spécial.','fr',FALSE,'vacances','couple','février 2025',NULL,NULL,NULL,NULL,'Cher Martin ! Merci infiniment pour votre retour si chaleureux et détaillé sur votre séjour au Martin Boutique Hotel. Nous sommes ravis d''apprendre que vous avez passé une semaine inoubliable parmi nous. Avec toute notre gratitude, Marion & l''équipe, Le Martin Boutique Hotel',0,'2025-02-15'),

('google','Coralie Weber',5,'A Slice of Paradise – Beyond Expectations. I had the pleasure of staying three nights at Le Martin Boutique Hotel. The hotel is stunning, intimate, beautifully designed with impeccable attention to detail.','en',FALSE,'vacances','couple','novembre 2024',NULL,NULL,NULL,NULL,'Chère Coralie, Nous vous remercions infiniment pour votre commentaire si chaleureux et sincère. Nous sommes ravis d''apprendre que votre séjour au Martin Boutique Hôtel a été exceptionnel. Bien cordialement, Marion et Idalia et toute l''équipe du Martin Boutique Hôtel',6,'2025-02-01'),

('google','Ségolène Pierrel',5,'Petit hôtel intime idéalement placé dans une résidence calme face à l''ilet Pinel. Nous avons était charmé par le soucis du détails et le soin avec lequel l''hôtel a été décoré. Nous reviendrons !','fr',FALSE,NULL,NULL,'juillet 2025',5.0,5.0,5.0,NULL,'Chère Ségolène, Merci infiniment pour votre retour si touchant. Nous sommes ravis que vous ayez été sensibles au soin apporté à la décoration et aux détails. À bientôt, Marion & l''équipe du Martin Boutique Hôtel',0,'2025-08-01'),

('google','alexandre pele',5,'Accueil chaleureux et chambre magnifique avec une vue incroyable !! Si vous voulez passer un séjour reposant ne cherchez plus c est l''endroit idéal.','fr',FALSE,'vacances','couple','mai 2024',NULL,NULL,NULL,NULL,NULL,0,'2024-06-01'),

('google','Damien Le Jeune',5,'Splendide séjour au Martin boutique Hôtel ! Lieu intimiste et élégant où nous avons été reçus avec gentillesse & professionnalisme par Marion et son équipe.','fr',FALSE,NULL,NULL,'février 2024',NULL,NULL,NULL,NULL,NULL,0,'2024-02-15'),

('google','Sophie BENSAID',5,'Quel plaisir de découvrir un endroit comme le Martin Boutique Hôtel, un compromis parfait entre l''hôtel et une maison de vacances. Tout y est paisible, serein, on s''y sent tellement bien, comme chez soi... mais en mieux car on se fait dorloter !','fr',FALSE,NULL,NULL,'octobre 2023',NULL,NULL,NULL,NULL,NULL,0,'2024-01-01'),

('google','Jessica SJ',5,'Le martin boutique hôtel est un endroit merveilleux, les chambres sont spacieuses, bien agencées, agréables, une literie de très bonne qualité, la décoration a été choisie avec soin. Les produits proposés sont d''une qualité inégalable.','fr',FALSE,NULL,'couple','juin 2024',NULL,NULL,NULL,NULL,NULL,5,'2024-07-01'),

('google','Sandra Segon',5,'Le brunch était de qualité, des produits frais et fait maison. La décoration de l''hôtel est juste waouhhh ! La piscine est très agréable. La végétation est magnifique. Les responsables et leur équipe sont au petit soins. Moment parfait pour notre séjour sur la belle île de Saint Martin','fr',FALSE,'vacances',NULL,'octobre 2022',NULL,5.0,5.0,NULL,'Sandra un grand merci pour votre visite. Trés belle rencontre ! Au grand plaisir de vous recevoir à nouveau ! L''équipe du Martin Hôtel',0,'2022-11-01'),

('google','Faycel Khebizi',5,'Nous avons eu la chance de découvrir non pas un hôtel mais plutôt un havre de quiétude et de tranquillité. Nous avons pris un brunch en famille composé d''excellents produits fait maison ( surtout la confiture mangue passion, elle est à tomber !).','fr',FALSE,'vacances','famille','octobre 2022',NULL,NULL,NULL,NULL,'Faycel, toute la team du Martin Boutique Hôtel vous remercie. Le plaisir a été partagé ! On vous attend l''année prochaine !',0,'2022-11-01'),

('google','Céline Allard',5,'Excellentissime expérience au Martin boutique hôtel chez Marion et Emmanuel ! L''hôtel est magnifique, intimiste (uniquement 6 chambres avec aucun vis à vis et insonorisation parfaite), il n''y a que des produits de luxe qui sont utilisés.','fr',FALSE,'vacances','famille','février 2024',NULL,NULL,NULL,NULL,NULL,5,'2024-03-01'),

('google','Camille Parpaleix',5,'Merci Marion et Emmanuel pour ce magnifique séjour ! Le petit boutique hôtel répond aux promesses types avec des chambres peu nombreuses et aussi privées que des appartements, un salon confortable et un espace terrasse avec piscine à disposition.','fr',FALSE,'vacances','couple',NULL,NULL,NULL,NULL,NULL,NULL,3,'2024-01-01'),

('google','juliette nissard',5,'Excellent, il n''y a pas d''autres mots, du début jusqu''à la fin, des hôtes aux petits soins avec ses clients et d''une très grande gentillesse. Nous avons séjourné 8 nuits et nous sommes sûrs de revenir le plus rapidement possible.','fr',FALSE,'vacances',NULL,'novembre 2022',NULL,NULL,NULL,NULL,'Chère Juliette, Emmanuel et moi même ainsi que toute l''équipe du Martin Boutique Hôtel vous remercie pour ce chaleureux message ! Le plaisir a été partagé ! Merci à vous ! Marion & Emmanuel Et la Martin Hôtel team !',0,'2022-12-01'),

('google','Patricia Rouquette',5,'Dès l''arrivée, l''accueil chaleureux et attentionné, l''ambiance cosy et élégante ainsi que la gentillesse de nos hôtes nous ont conquis. Marion et Emmanuel se sont attachés tout au long de la semaine à rendre notre séjour agréable.','fr',FALSE,'vacances','couple','mars 2023',NULL,NULL,NULL,NULL,'Patricia, Merci infiniment d''avoir pris le temps de partager cette excellente note et ce commentaire élogieux suite à votre séjour au Martin. Bien sincèrement, Marion & Emmanuel Et Toute l''équipe du Martin Boutique Hôtel',0,'2023-04-01'),

('google','Barbara Marie',5,'Un petit coin de paradis tout simplement. Le parfait équilibre entre un service au top, digne d''un hôtel de luxe, et une ambiance cocooning, relaxante qui fait que l''on se sent tellement bien et que l''on se croirait presque chez nous.','fr',FALSE,'vacances','couple','décembre 2022',NULL,NULL,NULL,NULL,'Chère Barbara, Toute l''équipe se joint à nous pour vous remercier. Quel plaisir d''avoir pu vous faire partager nos endroits favoris et insolites à St martin. A trés bientôt Barbara ! Marion & Emmanuel Ainsi que toute l''équipe du Martin Hôtel !',0,'2023-01-01'),

('google','Lisa Donan',5,'Nous avons passé en couple un excellent séjour en tout points à l''hôtel Martin boutique.','fr',FALSE,'vacances','couple','mai 2023',NULL,NULL,NULL,NULL,NULL,16,'2023-06-01'),

('google','Valerie Leibnitz',5,'Une équipe attentionnée et de bonne humeur. Un cadre propre et décoré avec goût et élégance. Merci d''avoir rendu notre escapade régénératrice.','fr',FALSE,'vacances','amis','novembre 2025',5.0,5.0,4.0,ARRAY['Luxueux','Romantique','Calme'],NULL,0,'2024-12-03'),

('google','Laurent Delassus',5,'Le Martin Boutique Hotel est un véritable "petit bijou"! Tout la décoration a été pensée avec énormément de goût! Par ailleurs, Marion, Emanuel et toute leur équipe sont aux petits soins pour vous faire découvrir St Martin et répondre à vos attentes. On se sent comme chez soi! Nous y reviendrons avec grand plaisir! Isabelle & Laurent','fr',FALSE,'vacances','couple','mars 2024',5.0,5.0,5.0,ARRAY['Luxueux','Beau panorama','Romantique','Calme'],NULL,0,'2025-03-01'),

('google','simon assidon',5,'Accueil exceptionnel hôtel fabuleux. La responsable Marion a des bons plans pour des journées bien remplies sans oublier le petit déjeuner excellent. Merci pour tout on reviendra rapidement.','fr',FALSE,'vacances','famille','août 2025',5.0,5.0,5.0,ARRAY['Luxueux','Beau panorama'],NULL,0,'2025-09-03'),

('google','Sylvie Jegou',5,'Il y a des lieux comme ça où on se sent bien immédiatement. Des lieux que l''on aimerait garder secrets, ou pour soi uniquement.','fr',FALSE,NULL,'amis','décembre 2022',NULL,NULL,NULL,NULL,NULL,0,'2023-01-01'),

('google','Chantal Rochat',5,'Superbe séjour de 14 nuits dans cet hôtel calme, à taille humaine, merci à Marion et Emmanuel et tout leur personnel pour votre accueil et votre gentillesse : 2 semaines de bonheur.','fr',FALSE,'vacances','couple','janvier 2024',NULL,NULL,NULL,NULL,NULL,0,'2024-02-01'),

('google','nelly martorana',5,'Nous avons passé LA journée parfaite !!! Détente et sérénité sont les maîtres mots de cet hôtel. Tout est pensé dans les moindres détails. La déco est soignée et raffinée.','fr',FALSE,NULL,'amis','octobre 2022',NULL,NULL,NULL,NULL,'Merci Nelly ! Ce fut un plaisir de vous accueillir ! Soyez les bienvenus à tout moment !',0,'2022-11-01'),

('google','NEOMARE VOYAGES',5,'Excellente escale détente, confort, design et aux petits soins des hôtes qui reçoivent avec Convivialité et sens du service haut de gamme. Magnifique boutique hôtel.','fr',FALSE,NULL,NULL,'janvier 2023',NULL,NULL,NULL,NULL,NULL,0,'2023-02-01'),

('google','France',5,'Nous avons adoré notre séjour. De l''accueil, au confort de la chambre, à la beauté et au raffinement des lieux, c''est un petit paradis qui gagne à être découvert. Nous y planifions déjà notre retour!','fr',FALSE,'vacances','couple','janvier 2025',5.0,5.0,5.0,ARRAY['Luxueux','Romantique','Calme','High-tech'],'Chére France, Merci beaucoup pour votre magnifique commentaire ! Nous sommes ravis de savoir que vous avez adoré votre séjour à Le Martin Boutique Hotel. Bien cordialement, Marion & L''équipe du Martin Boutique Hotel',0,'2025-02-01'),

('google','Julia Limousin',5,'Nous avons passé dix jours au Martin hôtel et en repartons avec l''envie de revenir ! Marion, Emmanuel et leur équipe nous ont accueillis si chaleureusement.','fr',FALSE,'vacances','couple',NULL,NULL,NULL,NULL,NULL,NULL,0,'2024-01-01'),

('google','mina nichols',5,'Cet écrin, lui même situé dans un véritable écrin de verdure est un lieu magnifique où le temps s arrête. De l''accueil au service en passant par le raffinement de la décoration comme celle du petit déjeuner : tout est pensé pour que la parenthèse soit enchantée.','fr',FALSE,'vacances','couple','juillet 2024',5.0,5.0,5.0,ARRAY['Luxueux','Beau panorama','Romantique','Calme'],NULL,0,'2025-02-01'),

('google','maya ait',5,'Y aller les yeux fermés… et se laisser bercer par la douceur de vivre. Nous avons passé, en couple, un séjour fabuleux en tous points et inoubliables. Tout a été mis en œuvre pour répondre avec justesse et délicatesse à nos envies.','fr',FALSE,'vacances','couple','mars 2023',NULL,NULL,NULL,NULL,NULL,0,'2023-04-01'),

('google','Isabelle Dreszer',5,'Un endroit très agréable ! Un service parfait ! Un petit dejeuner de qualité, un personnel accueillant très attentionné et toujours prêt à nous satisfaire et nous apporter leurs expériences sur l''île !','fr',FALSE,'vacances','famille','février 2023',NULL,NULL,NULL,NULL,NULL,7,'2023-03-01'),

('google','Florent Santiago',5,'Séjour inoubliable tout était tellement parfait. Un accueil exceptionnel. L''hôtel est située au calme au nord de l''île.','fr',FALSE,'vacances',NULL,'novembre 2022',NULL,NULL,NULL,NULL,'Cher Florent, Toute l''équipe se joint à nous pour vous remercier. Choses promises...choses faites. Rien de plus magique que d''être surpris à chaque instant ! Marion & Emmanuel Sarah, Félita, Héléna & Romain',0,'2022-12-01'),

('google','Danielle Quérel',5,'Un havre de paix d''excellence à l''esthétique raffinée où chaque détail est pensé pour offrir une expérience unique. Un cocon de douceur et de volupté pour seulement 6 magnifiques chambres.','fr',FALSE,'affaires','couple','juin 2024',NULL,NULL,NULL,NULL,NULL,3,'2025-02-01'),

('google','Mitchdabelew',5,'8 jours de pur bonheur dans cet espace cosi, chaleureux et de bon goût. Les chambres sont grandes, agréables et magnifiquement équipées. Tout est fait pour mettre à l''aise les clients. C''est simple on se sent immédiatement chez soi.','fr',FALSE,'vacances','couple','février 2023',NULL,NULL,NULL,NULL,NULL,0,'2023-03-01'),

('google','Claude Celestine',5,'Un petit coin de paradis dans lequel on aimerait rester plus longtemps... Le cadre, le brunch et l''accueil sont au top! Tout est réuni pour que l''on passe un bon et beau moment. Une déco et un endroit de rêves pour décompresser, je recommande sans hésiter!','fr',FALSE,'vacances',NULL,'novembre 2022',5.0,5.0,5.0,NULL,'Merci Célestine ! A trés vite ! Marion',0,'2022-12-01'),

('google','Julien Guitard',5,'Un boutique hotel design confidentiel de 6 chambres ouvert il y a un an. Grande attention donnée aux détails, au décor et à l''accueil - on se sent comme des amis reçus dans une maison personnelle.','fr',FALSE,'affaires','solo','novembre 2023',5.0,5.0,5.0,ARRAY['Calme','Bon rapport qualité-prix'],NULL,6,'2024-01-01'),

('google','Julien Doumergue',5,'Une très belle découverte. Un séjour d''une semaine au top, on se souviendra notamment de l''accueil chaleureux, du cadre magnifique, des très bons petits-déjeuners et des super conseils de nos hôtes. On a déjà hâte de revenir!','fr',FALSE,NULL,NULL,'décembre 2022',NULL,NULL,NULL,NULL,'Cher Julien, nous vous attendons !!! En attendant recevez quelques brins de soleil pour illuminer votre journée londoniennes hivernales ! A trés bientôt Marion & Emmanuel ainsi que l''équipe du Martin Boutique Hôtel',0,'2023-01-01'),

('google','Aurore COSTA',5,'Un magnifique site où l''on se sent comme à la maison. Nous avons pu profiter d''un massage en duo directement dans la Chambre. Je recommande l''expérience.','fr',FALSE,NULL,NULL,'mai 2024',5.0,5.0,5.0,NULL,NULL,0,'2025-02-01'),

('google','Christophe Guegan',5,'Merci à Marion, Emmanuel et à toute leur équipe pour ce magnifique séjour au Martin. C''était trop court, on doit revenir !','fr',FALSE,'vacances','couple','décembre 2024',5.0,5.0,5.0,ARRAY['Luxueux','Romantique'],'Cher Christophe, Un immense merci pour ce retour si positif et touchant ! Nous espérons sincèrement avoir le plaisir de vous recevoir à nouveau très bientôt pour un séjour plus long. À très vite pour de nouvelles aventures au Martin ! Avec toute notre gratitude, Marion, Emmanuel & toute l''équipe du Martin Boutique Hôtel',0,'2025-01-01'),

('google','Julien dtd',5,'Fabuleux ! En plus d''un cadre et d''une déco splendide Marion, Emanuel et son équipe sont aux petits soins ! Mention spéciale pour les petits déjeuners !','fr',FALSE,'vacances','couple','février 2023',5.0,5.0,5.0,NULL,NULL,6,'2023-03-01'),

('google','François Villalon',5,'Excellent séjour dans ce boutique hotel. On s''y sent comme à la maison. Les propriétaires et Sarah sont d''une grande gentillesse. Nous recommandons.','fr',FALSE,'vacances',NULL,'avril 2023',5.0,5.0,5.0,NULL,NULL,2,'2023-05-01'),

('google','Franck Vuillemin',5,'Superbe week-end en amoureux tout était parfait. Chambre magnifique décor soigné et personnel au top.','fr',FALSE,NULL,NULL,'juillet 2023',5.0,5.0,5.0,NULL,'Franck, Toute l''équipe se joint à nous pour vous remercier pour votre belle appréciation ! Au grand plaisir de vous accueillir de nouveau. À très bientôt ! Marion & Emmanuel',0,'2023-08-01'),

('google','christian schmitt',5,'Très bon accueil, personnel aux petits soins et propriétaires d''une extrême gentillesse je sais où nous irons lors de notre prochain séjour. Encore merci à Emmanuel et Marion.','fr',FALSE,'vacances','couple','mars 2023',5.0,5.0,5.0,ARRAY['Luxueux','Beau panorama','Calme'],NULL,0,'2023-04-01'),

('google','Victor-Emmanuel Lauhon',5,'Hôtel très agréable où il fait bon vivre pour y rester pour un court, moyen ou long séjour.','fr',FALSE,'vacances','solo','octobre 2024',5.0,5.0,4.0,ARRAY['Luxueux','Beau panorama','Calme','Bon rapport qualité-prix','High-tech'],'Cher Victor, Un grand merci pour votre retour si élogieux ! Ce sera un plaisir de vous accueillir de nouveau pour une autre expérience inoubliable à Saint Martin ! Avec toute notre gratitude, Marion, Emmanuel et l''équipe du Martin Boutique Hotel',0,'2025-01-01'),

('google','Cyril Touchard',5,'Délicieux petit-déjeuner, accueil chaleureux, superbe.','fr',FALSE,'vacances',NULL,'novembre 2022',NULL,NULL,NULL,NULL,'Merci Cyril ! C''était un réel plaisir de vous accueillir ! Marion',0,'2022-12-01'),

('google','Noizat Delphine',5,'Juste parfait!','fr',FALSE,NULL,NULL,'novembre 2025',5.0,5.0,5.0,NULL,NULL,0,'2024-12-03'),

('google','Mathilde Clerget',5,'Parenthèse enchantée. Je conseille vivement! Merci à toute l''équipe.','fr',FALSE,'vacances','couple','novembre 2023',5.0,5.0,5.0,NULL,NULL,0,'2024-01-01'),

('google','Patrice Nicolas',5,'Une équipe dans le partage et l''échange humain.','fr',FALSE,'vacances','couple','octobre 2023',5.0,5.0,5.0,ARRAY['Beau panorama','Romantique','Calme','Adapté aux enfants','Bon rapport qualité-prix'],NULL,0,'2024-01-01'),

('google','Philippe SAUREL',5,'Très bel endroit au calme et magnifiquement décoré. Le petit déjeuner est réellement délicieux. Bravo.','fr',FALSE,'vacances','couple','février 2026',5.0,4.0,4.0,NULL,NULL,0,'2026-02-24'),

('google','Richard Landau',5,'Nous avons passé quatre jours extraordinaires au Martin. Un établissement exceptionnel ! Les chambres étaient impeccables. Le souci du détail est remarquable dans la conception et la décoration. On se croirait dans un magazine de décoration.','en',TRUE,'vacances','couple','février 2026',NULL,NULL,NULL,NULL,NULL,0,'2026-02-10'),

('google','Steven Phillips',5,'L''hôtel Le Martin est un véritable havre de paix et de tranquillité. C''est notre deuxième séjour en deux ans.','en',TRUE,'vacances','couple','février 2026',NULL,NULL,NULL,NULL,NULL,3,'2026-02-03'),

('google','Alain Levi',5,'L''hôtel boutique Le Martin porte bien son nom. Dès votre arrivée, vous le ressentez dans l''ambiance, les chambres et le choix exceptionnel de matériaux, de couleurs et d''objets.','en',TRUE,'vacances','couple','janvier 2026',NULL,NULL,NULL,NULL,NULL,0,'2026-02-03'),

('google','Teet Tender',5,'Nous avons passé trois jours à l''hôtel et avons été ravis de notre séjour. Tout d''abord, le design de l''hôtel et la qualité des chambres, des espaces communs et des matériaux utilisés sont excellents. L''emplacement est idéal.','en',TRUE,'vacances','famille','décembre 2025',NULL,NULL,NULL,NULL,NULL,0,'2025-01-03'),

('google','jane dyball',3,'Nous avions choisi cet hôtel pour ses chambres familiales communicantes. À notre arrivée, on nous a annoncé que la suite familiale que nous avions réservée n''était pas disponible et on nous a relogés dans des chambres séparées.','en',TRUE,NULL,NULL,'janvier 2026',NULL,NULL,NULL,NULL,NULL,0,'2026-02-03'),

('google','Stephanie Morris',5,'Tout était absolument parfait durant notre séjour. Marion et son équipe ont été aux petits soins pour nous, des massages en chambre au service personnalisé au bord de la piscine tout au long de la journée. Les en-cas et petits-déjeuners étaient délicieux.','en',TRUE,'vacances','couple','novembre 2025',NULL,NULL,NULL,NULL,NULL,2,'2024-12-03'),

('google','Marijose Perez- Viñas',5,'Le Martin est tout simplement parfait. Niché à l''écart de l''agitation de l''île, c''est l''endroit idéal pour se détendre dans un cadre exceptionnel. Marion a un goût incroyable et l''hôtel est décoré avec un soin exquis.','en',TRUE,NULL,NULL,'novembre 2025',NULL,NULL,NULL,NULL,NULL,0,'2024-12-03'),

('google','Bryan Brager',5,'Notre séjour a été absolument incroyable. Cet hôtel de charme est un véritable havre de paix, tout simplement magnifique ; son design est superbe et on se croirait dans une villa privée.','en',TRUE,'vacances','couple','novembre 2025',NULL,NULL,NULL,NULL,NULL,6,'2024-12-03'),

('google','amy mulherin',5,'Les chambres étaient magnifiques, avec des vues imprenables et des terrasses. Le service était irréprochable et le personnel nous a traités comme des membres de la famille. Le petit-déjeuner était délicieux ! Un endroit magnifique.','en',TRUE,'vacances','couple','janvier 2026',NULL,NULL,NULL,NULL,NULL,0,'2026-02-03'),

('google','Megan Bradley',5,'Le personnel était exceptionnel, surtout Italia ! L''hôtel était super, conforme à la description sur leur site web. Nous avons particulièrement apprécié le petit-déjeuner préparé à la demande, la piscine ainsi que les espaces communs.','en',TRUE,NULL,NULL,'novembre 2025',NULL,NULL,NULL,NULL,NULL,6,'2025-01-03'),

('google','alissaturpin_google',5,'Je suis tellement contente que nous ayons trouvé cet hôtel, il était vraiment merveilleux ! On sent que les propriétaires y ont mis tout leur coeur et le résultat est magnifique.','en',TRUE,NULL,NULL,'novembre 2025',NULL,NULL,NULL,NULL,NULL,0,'2025-01-03'),

('google','Herve Laveaud',5,'Nous venons de passer quelques nuits à l''hôtel Le Martin Boutique à Saint-Martin – un véritable joyau caché.','en',TRUE,'vacances','couple','novembre 2025',NULL,NULL,NULL,NULL,NULL,3,'2024-12-03'),

('google','Mason',5,'J''ai passé un excellent séjour à l''hôtel Le Martin Boutique. La chambre était impeccable et confortable, et l''établissement dégageait une atmosphère paisible et détendue. Le personnel et les propriétaires étaient très agréables.','en',TRUE,'vacances','solo','novembre 2025',NULL,NULL,NULL,NULL,NULL,0,'2024-12-03'),

('google','Jay Miller',5,'Cet hôtel-boutique est tout simplement magnifique et nous avons adoré notre séjour. Les chambres, modernes et très confortables, offrent une vue imprenable sur Cul de Sac et l''Îlet de Pinel. Le petit-déjeuner était délicieux.','en',TRUE,'vacances',NULL,'décembre 2025',NULL,NULL,NULL,NULL,NULL,0,'2025-01-03'),

('google','Mary Beth Fransson',5,'Une atmosphère chaleureuse et accueillante… calme et sereine. Idalia et Amandine étaient des hôtesses aimables et attentionnées, toujours prêtes à rendre service.','en',TRUE,NULL,NULL,'février 2026',NULL,NULL,NULL,NULL,NULL,0,'2026-02-24'),

('google','Jack Parsons',5,'Nous avons passé un séjour absolument merveilleux ! Toute l''équipe du Martin est fantastique. L''emplacement est idéal. Tout est propre et bien agencé. Nous recommanderons sans hésiter Le Martin à tous nos amis.','en',TRUE,'vacances','couple','décembre 2025',NULL,NULL,NULL,NULL,NULL,0,'2025-01-03'),

('google','Sophie Johnson',5,'Un établissement absolument magnifique, un petit-déjeuner délicieux et un service impeccable ! J''appréhendais mon premier voyage à Saint-Martin, alors j''ai contacté le complexe quelques semaines avant pour me renseigner.','en',TRUE,'vacances','solo','juillet 2025',NULL,NULL,NULL,NULL,NULL,4,'2025-09-03'),

('google','Alexander Viamari',5,'Mon partenaire et moi avons séjourné à l''hôtel Le Martin et que dire de cet endroit ? Le petit-déjeuner était excellent, le souci du détail remarquable, le personnel aux petits soins et le cadre magnifique.','en',TRUE,NULL,NULL,'novembre 2025',NULL,NULL,NULL,NULL,NULL,0,'2024-12-03'),

('google','Emily Ortiz Badalamente',5,'C''était notre premier séjour à Saint-Martin et nous n''aurions pas pu rêver d''une meilleure première expérience. L''hôtel bénéficie d''une situation idéale côté français, parfaite pour explorer l''île, ses excellents restaurants et ses magnifiques plages.','en',TRUE,'vacances','couple','juillet 2025',NULL,NULL,NULL,NULL,'Chère Emily, merci infiniment pour vos mots si touchants ; ils nous font vraiment très plaisir. Nous sommes profondément honorés d''avoir contribué à votre toute première expérience à Saint-Martin. Nous espérons vous accueillir à nouveau ; votre havre de paix vous attend. Bien cordialement, Marion et l''équipe du Martin Boutique Hotel',2,'2025-08-01'),

('google','heidi slimm',5,'Sans voix ! Ce que Marion, sa famille et son équipe ont créé est tout simplement parfait. Le décor chic et apaisant, l''hospitalité, la sérénité, les petits déjeuners… tout est phénoménal. Sincèrement.','en',TRUE,'vacances','famille','décembre 2025',NULL,NULL,NULL,NULL,NULL,0,'2025-01-03'),

('google','Stephanie Sin',5,'Quel magnifique séjour ! La chambre était spacieuse et confortable, et les espaces communs offraient une ambiance chaleureuse et accueillante. L''emplacement est idéal, à mi-chemin entre Orient Beach et Anse Marcel.','en',TRUE,'vacances','couple','novembre 2025',NULL,NULL,NULL,NULL,NULL,7,'2024-12-03'),

('google','Dan Cato Olsson',5,'Une petite aventure à l''hôtel Le Martin Boutique. Séjour extraordinaire, cadre magnifique, personnel exceptionnel.','en',TRUE,'vacances','couple','octobre 2025',NULL,NULL,NULL,NULL,NULL,0,'2024-12-03'),

('google','Kaitlyn Harrison',5,'Après quelques recherches sur les destinations de vacances, mon copain et moi avons jeté notre dévolu sur Saint-Martin. Et nous sommes ravis d''avoir trouvé l''hôtel Le Martin ! Dès notre arrivée, nous avons été aux petits soins.','en',TRUE,'vacances','couple','février 2025',NULL,NULL,NULL,NULL,'Chère Kaithlyn, Merci pour votre excellent avis ! Nous sommes ravis que vous et votre compagnon ayez choisi Saint-Martin pour vos vacances, et encore plus heureux que Le Martin ait fait partie de votre escapade ! Cordialement, Marion et l''équipe du Martin Boutique Hotel',1,'2025-04-01'),

('google','Lorraine Forster',5,'Nous avons adoré notre séjour au Martin ! L''équipe a été aux petits soins et l''hôtel ainsi que les chambres étaient magnifiques. Nous avons hâte d''y retourner.','en',TRUE,'vacances','amis','janvier 2026',NULL,NULL,NULL,NULL,NULL,0,'2026-02-03'),

('google','Nicole Gouverneur',5,'Hôtel charmant et intimiste. Tout était parfait ! Du style au ménage, du petit-déjeuner à la lecture dans le salon commun. Emplacement idéal, quartier/rue calme. Personnel accueillant.','en',TRUE,'vacances','couple','janvier 2026',NULL,NULL,NULL,NULL,NULL,0,'2026-02-03'),

('google','Anjeanette Massey',5,'Ce petit hôtel de charme est un véritable bijou, un secret bien gardé de l''île, alliant élégance et luxe. Ivanna et Marion ont été d''une gentillesse et d''une aide précieuses, nous prodiguant de précieux conseils sur les meilleures plages et restaurants.','en',TRUE,'vacances','famille','juillet 2025',NULL,NULL,NULL,NULL,'Chère Anjeanette, Nous sommes vraiment touchés que votre séjour au Martin vous ait donné l''impression de découvrir un trésor secret. Ivanna et moi avons été ravis de vous aider à profiter au maximum de votre séjour sur l''île. Cordialement, Marion et toute l''équipe du Martin',0,'2025-08-01'),

('google','Thomas Warren',5,'Nous avons passé notre lune de miel à l''hôtel Le Martin. Notre séjour de 10 nuits a été tout simplement parfait. Le personnel est incroyablement serviable : de bons conseils, réservations de restaurant… et leur petit-déjeuner est exceptionnel.','en',TRUE,'vacances','couple','juin 2025',NULL,NULL,NULL,NULL,'Cher Thomas, Nous vous remercions infiniment pour votre commentaire détaillé et si touchant. Nous sommes ravis d''avoir contribué à rendre votre lune de miel inoubliable. Nous espérons avoir le plaisir de vous accueillir à nouveau. Avec toute notre gratitude, Marion et l''équipe du Martin Boutique Hotel',6,'2025-07-01'),

('google','Katlin Catapano',5,'Si je pouvais donner plus de cinq étoiles au Le Martin Boutique Hotel, je le ferais. L''hôtel était chic, calme et bien entretenu. La vue sur l''îlet Pinel depuis notre balcon était imprenable. Ce qui nous a le plus marqués, c''est l''équipe.','en',TRUE,'vacances','couple','mars 2025',NULL,NULL,NULL,NULL,'Chère Kathin, quel plaisir de lire vos mots si gentils ! Nous sommes ravis que vous ayez apprécié l''atmosphère paisible et élégante du Martin, la vue imprenable depuis votre balcon et, surtout, les soins et l''attention de notre équipe. Bien cordialement, Marion, Idalia et toute l''équipe',0,'2025-04-01'),

('google','Ian Spain',5,'Nous avons adoré notre séjour ! Un charmant petit hôtel de charme dans un quartier calme, avec une chambre agréable et une superbe piscine/salon. Le petit-déjeuner inclus était excellent et le service, amical et attentif.','en',TRUE,NULL,NULL,'mai 2025',NULL,NULL,NULL,NULL,'Cher Ian, Nous vous remercions chaleureusement pour votre charmant commentaire. Nous sommes ravis que vous ayez apprécié la tranquillité de notre hôtel. Bien cordialement, Marion et l''équipe du Martin Boutique Hotel',0,'2025-06-01'),

('google','Joe',5,'Mon hôtel-boutique préféré, celui où j''ai séjourné le plus souvent. Nous y retournerons sans hésiter. Le personnel est d''une gentillesse et d''une serviabilité exceptionnelles ; ils font tout leur possible pour que l''on se sente chez soi.','en',TRUE,'vacances','couple','juin 2025',NULL,NULL,NULL,NULL,'Cher Joe, Nous vous remercions du fond du cœur pour cet excellent avis. Savoir que Le Martin est devenu votre hôtel-boutique préféré est le plus beau compliment que nous puissions recevoir. Avec toute notre gratitude, Marion et toute l''équipe',0,'2025-07-01'),

('google','Lily Johnson',5,'Marion et l''équipe du Martin ont rendu notre séjour inoubliable, à la fois relaxant et divertissant. Nous avons particulièrement apprécié le petit-déjeuner au bord de la piscine, la location de kayaks pour l''île Pinel.','en',TRUE,NULL,NULL,'mai 2025',NULL,NULL,NULL,NULL,'Chère Lily, Merci infiniment pour votre commentaire enthousiaste. Nous sommes ravis que votre séjour ait été à la fois relaxant et divertissant. Nous serions honorés de vous accueillir à nouveau lors de votre prochain séjour à Saint-Martin. Bien cordialement, Marion et l''équipe',0,'2025-06-01'),

('google','Corindel S',5,'Un merveilleux hôtel-boutique offrant un service personnalisé exceptionnel et un excellent petit-déjeuner. Chambres spacieuses avec machine à café Nespresso et réfrigérateur. Nous avons beaucoup apprécié notre court séjour.','en',TRUE,'vacances','couple','octobre 2025',NULL,NULL,NULL,NULL,NULL,1,'2024-11-03'),

('google','LP',5,'Un tout petit hôtel chic. Le design est de bon goût mais le confort est indéniable. C''est un établissement très élégant. Ceci dit, notre enfant de 11 ans s''est senti plus que bienvenu. Le service assuré par Edalia était exceptionnel.','en',TRUE,'vacances','famille','février 2025',NULL,NULL,NULL,NULL,'Cher LP, Merci beaucoup pour votre avis ! Nous sommes ravis que vous et votre famille ayez apprécié votre séjour au Le Martin Boutique Hotel. Nous vous remercions sincèrement pour votre recommandation. Cordialement, Marion, Idalia, Charlotte, Ivana, Félita, Héléna, Chilène',0,'2025-04-01'),

('google','Leo Trinidad',5,'En tant que directrice artistique, j''ai un don pour le design, et Le Martin Boutique Hotel ne m''a pas déçue. J''y ai passé sept nuits et, dès mon arrivée, j''ai eu l''impression d''entrer dans une oasis privée. L''esthétique est d''une élégance moderne et d''un charme caribéen absolument saisissants.','en',TRUE,'vacances','amis','février 2025',NULL,NULL,NULL,NULL,'Cher Leo, Merci pour votre avis incroyable et détaillé ! En tant que directeur artistique, votre goût pour le design est précieux pour moi, et nous sommes ravis que Le Martin Boutique Hotel ait répondu à vos attentes. Cordialement, Marion et l''équipe du Martin Boutique Hotel',11,'2025-04-01'),

('google','Natalia Brownleader',5,'Nous y avons passé notre lune de miel et notre séjour dans cet hôtel-boutique a été tout simplement parfait. Dès notre arrivée, nous avons été enchantés par la beauté de la propriété et l''accueil chaleureux du personnel.','en',TRUE,'vacances','couple','janvier 2025',NULL,NULL,NULL,NULL,'Chère Natalia, Merci infiniment pour vos merveilleux mots. Nous sommes ravis d''apprendre que votre séjour parmi nous a été à la hauteur de vos espérances et que nous avons pu rendre votre lune de miel encore plus spéciale. Cordialement, Marion, Emmanuel & Idalia',0,'2025-02-01'),

('google','Sasha Krutiy',5,'Notre expérience au Martin a été spectaculaire ! L''hôtel lui-même est magnifique et on sent qu''il a été conçu avec beaucoup d''attention et de soin. L''ambiance était très personnalisée, le personnel était sympathique.','en',TRUE,'vacances','couple','février 2025',NULL,NULL,NULL,NULL,'Chère Sasha, Merci pour votre avis élogieux ! Nous sommes ravis d''apprendre que votre expérience au Martin a été tout simplement exceptionnelle. Cordialement, Marion et l''équipe du Martin Boutique Hotel',3,'2025-04-01'),

('google','Henric Blomsterberg',5,'Nous avons séjourné au Martin du 4 au 6 février 2025 et avons passé un séjour fantastique. L''hôtel n''était pas au bord de l''eau, mais il y avait une superbe piscine et, à quelques pas, un petit ponton d''où l''on pouvait prendre un bateau pour l''île Pinel.','en',TRUE,NULL,NULL,'février 2025',NULL,NULL,NULL,NULL,'Cher Henric, Merci infiniment pour vos gentils mots et d''avoir partagé votre expérience au Le Martin Boutique Hotel. Ce fut un réel plaisir de vous accueillir. Bien cordialement, Marion',0,'2025-03-01'),

('google','Ben Duquesne',5,'Nous avons adoré notre séjour. Marion, la propriétaire, était adorable et très accueillante. C''était un vrai plaisir de discuter avec elle. L''hôtel est magnifiquement décoré et conçu avec beaucoup de goût ; il offre une vue magnifique sur la baie.','en',TRUE,'vacances','couple','juin 2024',NULL,NULL,NULL,NULL,NULL,0,'2025-03-01'),

('google','Allegra VanderWilde',5,'Nous n''avons que des éloges à faire de notre séjour au Martin ; l''hôtel a véritablement sublimé nos vacances. Son design est d''un goût exquis : intime, privé, magnifique, d''une élégance sobre et raffinée. La cuisine est excellente.','en',TRUE,'vacances','couple','mai 2025',NULL,NULL,NULL,NULL,'Chère Allegra, Quel plaisir de lire vos merveilleux mots ! Merci infiniment de les avoir partagés. Savoir que Le Martin a contribué à rendre vos vacances exceptionnelles est pour nous la plus belle des récompenses. Avec toute notre gratitude, Marion et l''équipe du Martin Boutique Hotel',0,'2025-06-01'),

('google','Basti Balk',5,'Un hôtel plein de charme avec une touche personnelle. Le personnel est incroyablement aimable et les chambres sont modernes et bien équipées. L''espace extérieur comprend une belle piscine et une terrasse, idéales pour se détendre.','en',TRUE,'vacances','couple','juillet 2025',NULL,NULL,NULL,NULL,'Cher Basti, quel plaisir de lire votre message ! Merci sincèrement d''avoir pris le temps de partager votre expérience. Nous espérons vous revoir bientôt à Saint-Martin. Bien cordialement, Marion et l''équipe du Martin Boutique Hotel',0,'2025-08-01'),

('google','Jessica Miao',5,'Mon mari et moi avons séjourné au Martin pour notre lune de miel et c''était plus que parfait ! Le Martin est tout simplement magnifique : magnifiquement conçu et décoré, tout en étant à la fois décontracté et sophistiqué.','en',TRUE,'vacances','couple','novembre 2024',NULL,NULL,NULL,NULL,'Chère Jessica, merci infiniment pour votre commentaire si touchant et pour avoir partagé de si beaux souvenirs de votre séjour de lune de miel au Le Martin Boutique Hôtel. Bien cordialement, Marion et l''équipe de l''Hôtel Boutique Le Martin',0,'2025-01-01'),

('google','Abby',5,'L''endroit idéal pour les aventuriers ! Nous avons séjourné au Martin pour notre lune de miel et c''était tout ce que nous pouvions espérer, et même plus. L''emplacement est idéal. Il offre intimité et vue sur l''océan.','en',TRUE,'vacances','couple','novembre 2024',NULL,NULL,NULL,NULL,'Chère Abby, Quel plaisir de lire votre commentaire si touchant et détaillé ! Ce fut un véritable honneur de participer à votre lune de miel. Avec toute notre gratitude et nos meilleurs vœux pour ce nouveau départ à deux, Marion, Emmanuel et toute l''équipe du Martin Boutique Hotel',0,'2025-01-01'),

('google','John Damianakis',4,'Nous avons récemment passé 10 jours au Le Martin Boutique Hotel et, dans l''ensemble, ce fut une expérience agréable. Les chambres sont spacieuses, avec des salles de bain bien équipées, et offrent une vue imprenable sur la baie.','en',TRUE,'vacances','famille','mai 2024',NULL,NULL,NULL,NULL,NULL,0,'2025-02-01'),

('google','Kimberly Oddo',5,'Mon mari et moi avons séjourné à l''hôtel Le Martin pour notre escapade prénatale et nous avons adoré l''établissement. Tout a été pensé dans les moindres détails, du sac de plage fourni dans notre chambre au délicieux petit-déjeuner servi chaque matin.','en',TRUE,'vacances','couple','mai 2024',NULL,NULL,NULL,NULL,NULL,0,'2025-02-01'),

('google','Della Bradt',5,'Cet hôtel est un véritable bijou ! Chaque détail est impeccable et l''établissement est magnifique. Le personnel est incroyablement accueillant et de très bon conseil. Le petit-déjeuner est délicieux et l''espace piscine est superbe.','en',TRUE,'vacances','couple','février 2025',NULL,NULL,NULL,NULL,'Chère Della, merci infiniment pour votre merveilleux commentaire ! Nous sommes ravis que votre séjour vous ait plu. Ce fut un réel plaisir de vous accueillir lors de votre escapade prénatale. Marion',3,'2025-03-01'),

('google','Tara Polla',5,'J''ai adoré mon séjour au Martin. Dès qu''on y entre, on a l''impression d''arriver chez sa meilleure amie, une vraie fashionista. Les chambres, la déco et les équipements étaient absolument parfaits. Tout le personnel était adorable.','en',TRUE,'vacances','solo','décembre 2024',NULL,NULL,NULL,NULL,'Merci Tara pour votre commentaire élogieux sur votre séjour au Le Martin Boutique Hôtel ! Nous sommes ravis que vous vous soyez sentie comme chez vous, comme chez une amie élégante. Nous espérons avoir le plaisir de vous accueillir à nouveau à Saint-Martin. Marion',0,'2025-01-01'),

('google','Kristin Hayrinen',5,'Un séjour exceptionnel dans ce magnifique hôtel-boutique ! Ambiance familiale et conviviale à la piscine et dans les espaces communs, personnel compétent et aimable. Ma fille et moi y avons passé plusieurs nuits et nous n''avions pas envie de partir.','en',TRUE,'vacances',NULL,'mai 2025',NULL,NULL,NULL,NULL,'Chère Kristin, Quel plaisir de lire votre message et de voir vos magnifiques photos du lever de soleil sur la baie ! Ce serait un réel plaisir de vous accueillir à nouveau et de continuer à créer de beaux souvenirs ensemble. Avec toute notre gratitude, Marion et l''équipe de l''Hôtel Boutique Le Martin',4,'2025-06-01'),

('google','Katherine Wang',5,'Nous avons passé un séjour fantastique au Martin, un point de départ idéal pour explorer l''île. La chambre était impeccable et le petit-déjeuner excellent chaque matin. Idalia nous a été d''une aide précieuse pour planifier nos journées.','en',TRUE,'vacances','couple','février 2025',NULL,NULL,NULL,NULL,'Chère Kathetine, Merci pour votre excellent avis ! Nous sommes ravis d''apprendre que vous avez passé un séjour fantastique au Martin. Cordialement, Marion et l''équipe du Martin Boutique Hotel',0,'2025-04-01'),

('google','Nicole S',5,'Nous avons passé un séjour merveilleux à l''hôtel Le Martin. Nous fêtions les 40 ans de mon mari et le personnel s''est mis en quatre pour rendre notre voyage inoubliable. Ils étaient aux petits soins et ont répondu à toutes nos demandes.','en',TRUE,'vacances','couple','novembre 2024',NULL,NULL,NULL,NULL,'Chère Nicole, Quel plaisir de lire vos gentils mots après une célébration si mémorable ! Ce fut un véritable honneur de vous accueillir tous les deux pour les 40 ans de votre mari. Avec toute notre gratitude, Marion, Emmanuel et toute l''équipe du Martin Boutique Hotel',0,'2025-01-01'),

('google','Cassie Cowman',5,'J''adore cet hôtel-boutique ! Sans aucun doute l''un des endroits les plus chics de SXM. L''emplacement est calme et privé, avec un ponton privé pour nager et faire du paddle. La piscine est calme et avec ses 6 chambres, l''atmosphère est très intime.','en',TRUE,'vacances','couple',NULL,NULL,NULL,NULL,NULL,NULL,3,'2024-01-01'),

('google','ANTHONY CUCCULELLI',5,'L''hôtel Le Martin Boutique est un véritable joyau caché. Sans conteste l''un de nos hôtels préférés. L''équipe était chaleureuse et accueillante, désireuse de partager sa connaissance de l''île. L''emplacement est idéal.','en',TRUE,'vacances','couple','avril 2023',NULL,NULL,NULL,NULL,'Cher Anthony, Emmanuel, moi même et toute l''équipe du Martin Boutique Hôtel vous remercie pour votre commentaire. Votre escape chez nous fut un plaisir partagé. Marion & Emmanuel',0,'2023-05-01'),

('google','Brenna O''Dell',5,'Visiter l''hôtel Le Martin a été une expérience incroyable ! Tout le personnel était très sympathique et serviable. Mon copain et moi y avons passé 5 nuits. La nourriture était délicieuse, l''hôtel était très propre et magnifiquement décoré.','en',TRUE,'vacances','couple','juin 2024',NULL,NULL,NULL,NULL,NULL,5,'2025-02-01'),

('google','Sandie Dai',5,'Nous avons passé un séjour fabuleux au Martin. Le personnel est très attentionné et poli. Nous avons adoré le design de l''hôtel. On se serait presque cru dans un spa scandinave. Le petit-déjeuner offert était absolument délicieux.','en',TRUE,NULL,NULL,'juin 2024',NULL,NULL,NULL,NULL,NULL,6,'2025-02-01'),

('google','Arman HOVSEPYAN',5,'J''ai passé un séjour absolument incroyable à l''hôtel-boutique Le Martin ! Dès mon arrivée, j''ai été enveloppé d''une atmosphère empreinte de romantisme et de poésie. Chaque détail avait été pensé avec soin, créant une expérience unique et mémorable.','en',TRUE,NULL,NULL,'juillet 2023',NULL,NULL,NULL,NULL,NULL,0,'2024-01-01'),

('google','Tomek Lapa',5,'De la réservation à l''entrée dans la propriété du Martin, en passant par notre chambre, notre délicieux petit-déjeuner et tout notre séjour… nous qualifions Le Martin de STELLAIRE, dépassant toutes nos attentes. Toute l''expérience a dépassé nos attentes.','en',TRUE,'vacances','couple','janvier 2024',NULL,NULL,NULL,NULL,NULL,0,'2024-02-01'),

('google','Fri Lavey',5,'Séjourner au Martin était un rêve. L''hôtel est une oasis de beauté. Le petit-déjeuner est délicieux. Les chambres sont paisibles, mais le personnel a vraiment fait la différence. Ils nous ont réservé un accueil exceptionnel.','en',TRUE,NULL,NULL,'mai 2024',NULL,NULL,NULL,NULL,NULL,0,'2025-02-01'),

('google','Lauren Pugh',5,'Mon conjoint et moi avons séjourné au Martin pendant 11 nuits. Vraiment une expérience spectaculaire. L''attention portée aux détails par Marion dans tout l''hôtel est impeccable.','en',TRUE,NULL,NULL,'mai 2024',NULL,NULL,NULL,NULL,NULL,0,'2025-02-01'),

('google','Kellie Ferrier',5,'Un rêve ! Marion et son équipe ont créé l''hôtel le plus luxueux, relaxant et attentionné qui soit. Tout est facile à parcourir en voiture. L''hôtel lui-même est digne d''un film. Le petit-déjeuner au bord de la piscine est exceptionnel.','en',TRUE,'vacances','couple','juin 2024',NULL,NULL,NULL,NULL,NULL,0,'2025-02-01'),

('google','Nicolai Tandrup',5,'De mon arrivée à mon départ, je me suis senti comme un client privilégié. Ce qui distingue vraiment Le Martin, c''est son souci exceptionnel du détail. Le personnel se surpasse en vous fournissant de précieuses recommandations.','en',TRUE,'vacances','amis','novembre 2023',NULL,NULL,NULL,NULL,NULL,3,'2024-02-01'),

('google','Max Applebaum',5,'J''ai récemment eu le plaisir de séjourner au Le Martin Boutique Hôtel, et ce fut une expérience absolument merveilleuse du début à la fin.','en',TRUE,'vacances','couple','décembre 2023',NULL,NULL,NULL,NULL,NULL,0,'2024-03-01'),

('google','Kevin Marques',5,'Nous avons séjourné à l''hôtel-boutique Le Martin du 3 au 10 février 2025 et avons vraiment adoré notre séjour. De notre arrivée à notre départ le 10 au matin, Marion et son équipe ont toujours été disponibles pour nous.','en',TRUE,NULL,NULL,'février 2025',NULL,NULL,NULL,NULL,'Cher Kevin, Merci beaucoup pour votre excellent avis ! Nous sommes ravis d''apprendre que votre séjour au Martin Boutique Hotel a été mémorable. Cordialement, Marion et l''équipe du Martin Boutique Hotel',0,'2025-04-01'),

('google','Greg',5,'Nous avons rencontré un problème avec notre site de réservation, mais le personnel du Martin a résolu le problème avec brio. Nous étions ravis. L''hôtel nous a donné l''impression d''être chez l''habitant. Le personnel a été aux petits soins.','en',TRUE,NULL,NULL,'décembre 2024',NULL,NULL,NULL,NULL,'Cher Greg, merci de nous avoir fait part de votre aimable retour. Nous sommes ravis d''avoir pu résoudre le problème de votre réservation et que vous vous soyez senti bien accueilli. Cordialement, Marion et Emmanuel',1,'2025-01-01'),

('google','Katherine Hurewitz',5,'Hôtel absolument magique. Niché à l''abri des regards, on a l''impression d''avoir découvert une maison secrète conçue spécialement pour soi. Le personnel est aux petits soins et le petit-déjeuner offert comprend jus de fruits frais, viennoiseries maison.','en',TRUE,NULL,NULL,'mars 2025',NULL,NULL,NULL,NULL,'Chère Katherine, merci pour vos précieux mots ! Nous sommes ravis que vous ayez eu l''impression de découvrir un trésor caché. Nous espérons vous accueillir à nouveau bientôt dans cette petite oasis ! Marion',0,'2025-04-01'),

('google','Valerie Diallo Bazie',5,'Nous avons eu le plaisir de passer quelques jours au Martin et nous avons hâte d''y retourner ! L''hôtel est exceptionnel ! On s''y sent comme à la maison, dans une atmosphère relaxante, luxueuse et conviviale.','en',TRUE,'vacances','famille','avril 2024',NULL,NULL,NULL,NULL,NULL,0,'2025-03-01'),

('google','Phil Rosenberg',5,'Marion et Emanuel (+ Sarah) font un travail fantastique pour que vous vous sentiez comme chez vous au Le Martin Boutique Hotel. Ils connaissent les meilleurs restaurants et les meilleurs clubs de plage et ont un goût impeccable.','en',TRUE,'vacances','couple','février 2023',NULL,NULL,NULL,NULL,NULL,0,'2024-01-01'),

('google','Jenni Young',5,'Je recommande vivement l''hôtel Le Martin Boutique à Saint-Martin ! Cet hôtel est tout simplement magnifique, avec des chambres propres et spacieuses, des espaces communs accueillants et une superbe piscine !','en',TRUE,'vacances','famille','avril 2023',NULL,NULL,NULL,NULL,NULL,0,'2024-01-01'),

('google','Abby Caulfield',5,'Notre séjour à Saint-Martin a été véritablement sublimé par notre séjour dans cet hôtel. La qualité des chambres, les vues panoramiques, l''offre culinaire, les équipements de la piscine et le service exemplaire du personnel ont été des points forts.','en',TRUE,'vacances','couple','janvier 2024',NULL,NULL,NULL,NULL,NULL,0,'2024-02-01'),

('google','Nicholas Carpenito',5,'Mon épouse et moi avons récemment eu le plaisir de passer nos vacances à l''hôtel Le Martin et ce fut tout simplement fantastique. Nous ne séjournons généralement pas dans des hôtels de charme, mais celui-ci nous a conquis.','en',TRUE,NULL,NULL,'février 2024',NULL,NULL,NULL,NULL,NULL,0,'2024-03-01'),

('google','Britt S',5,'Nous avons adoré notre séjour au Martin. Nous y avons passé une semaine de vacances et avons hâte d''y retourner !','en',TRUE,'vacances','couple','novembre 2022',NULL,NULL,NULL,NULL,'Cher B. Après une arrivée tant attendue, nous sommes ravis d''avoir contribué à faire de vos vacances une belle découverte. Marion et Emanuel',0,'2023-01-01'),

('google','Sydney G.',5,'Nous avons vécu une expérience absolument exceptionnelle au Martin. La propriété est magnifique ; les chambres et l''espace commun avec piscine sont spacieux et magnifiquement conçus, et tout est impeccable.','en',TRUE,NULL,NULL,'décembre 2022',NULL,NULL,NULL,NULL,'Toute l''équipe de l''Hôtel Martin se joint à nous pour vous remercier de votre gentil message. Quel plaisir de vous voir revenir au plus vite de vos escapades autour de l''île. Marion et Emanuel et toute l''équipe !',7,'2023-01-01'),

('google','Haylei P',5,'J''ai passé un merveilleux séjour. Marion et toute l''équipe se soucient vraiment du confort et de l''expérience globale de leurs clients, non seulement à l''hôtel, mais aussi sur l''île. Ils ont été accueillants et attentifs.','en',TRUE,'vacances',NULL,'octobre 2024',NULL,NULL,NULL,NULL,'Chère Haylei, Nous vous remercions sincèrement pour votre commentaire. Ce fut un plaisir de vous accueillir au Martin Boutique Hotel. À bientôt, et merci encore pour vos gentils mots. Bien cordialement, Marion et l''équipe du Martin Boutique Hotel',0,'2025-02-01'),

('google','kelly fisher',5,'L''hôtel-boutique Le Martin a fait de notre séjour à Saint-Martin un moment inoubliable. Cinq étoiles sur toute la ligne ! Un personnel attentionné, une cuisine délicieuse (pâtisseries maison, jus de fruits frais) et des chambres raffinées.','en',TRUE,'vacances','couple','février 2024',NULL,NULL,NULL,NULL,NULL,5,'2024-03-01'),

('google','Karina Rykman',5,'Quelle expérience merveilleuse ! Le personnel était incroyablement serviable, aimable et attentionné, l''ambiance du petit-déjeuner est tout simplement phénoménale, la piscine est sublime et nous avons passé un séjour fantastique.','en',TRUE,'vacances','couple','juin 2025',NULL,NULL,NULL,NULL,'Chère Karina, Quel plaisir de lire le récit de votre agréable expérience ! Merci beaucoup pour vos aimables mots. Nous espérons avoir le plaisir de vous accueillir à nouveau très prochainement au Martin. Avec toute notre gratitude, Marion et toute l''équipe',0,'2025-09-03'),

('google','Michelle Im',5,'Magnifique hôtel offrant intimité et tranquillité. Propreté et service impeccables. Ma meilleure amie et moi étions en voyage entre filles et nous n''aurions pas pu trouver meilleur hôtel. Le personnel était formidable.','en',TRUE,NULL,NULL,'avril 2025',NULL,NULL,NULL,NULL,'Chère Michelle, quel plaisir de lire votre message ! Nous sommes ravis que votre escapade entre filles se soit déroulée à merveille au Martin. Bien cordialement, Marion et toute l''équipe du Martin Boutique Hotel',0,'2025-05-01'),

('google','Myriam Gumuchian',5,'Nouvel hôtel boutique idyllique situé dans une impasse. Cet hôtel de 6 chambres est l''endroit idéal pour se détendre et oublier tous ses soucis. Les propriétaires, Marion et Emmanuel, vous accueillent chaleureusement.','en',TRUE,'vacances','couple','janvier 2024',NULL,NULL,NULL,NULL,NULL,0,'2024-02-01'),

('google','Phil Shaw',5,'Ce petit hôtel est un 5 étoiles du début à la fin. C''est un havre de paix incroyable. La décoration, le mobilier et le design sont contemporains mais chaleureux ; apaisants mais intéressants ; contemplatifs mais stimulants.','en',TRUE,NULL,NULL,'août 2023',NULL,NULL,NULL,NULL,NULL,0,'2024-01-01'),

('google','Sarah Grissa',5,'Nous avons passé un séjour parfait à l''hôtel Le Martin avec mon mari et notre petit garçon. Un grand merci à Marion et Emmanuel pour votre gentillesse et votre accueil dans votre magnifique hôtel. Nous nous sentons vraiment comme à la maison.','en',TRUE,'vacances','famille',NULL,NULL,NULL,NULL,NULL,NULL,0,'2025-02-01'),

('google','C M',5,'J''ai récemment séjourné au Le Martin Boutique Hotel. Je cherche encore les mots pour décrire cette expérience incroyable. La chambre (The Martha) était magnifique, neuve et propre. La vue était spectaculaire.','en',TRUE,NULL,NULL,'décembre 2023',NULL,NULL,NULL,NULL,NULL,0,'2024-01-01'),

('google','C B',5,'Notre séjour au Martin a été incroyable. Si vous envisagez de séjourner ici… vous ne le regretterez pas ! Le service est exceptionnel. Le petit-déjeuner personnalisé chaque matin est exceptionnel. Chaque détail est parfaitement pensé.','en',TRUE,'vacances','couple','juin 2024',NULL,NULL,NULL,NULL,NULL,0,'2025-02-01'),

('google','Jin Choi',5,'Un charmant hôtel situé dans une résidence sécurisée du côté français de l''île, avec un accès facile aux nombreuses plages et restaurants de Grand Case ! Cet hôtel-boutique offre une vue imprenable sur la baie et les îlets.','en',TRUE,'vacances','famille','novembre 2024',NULL,NULL,NULL,NULL,'Cher Jin, Merci infiniment pour vos gentils mots et d''avoir pris le temps de partager votre expérience au Martin Boutique Hotel. Nous espérons avoir le plaisir de vous accueillir à nouveau très prochainement dans notre petit coin de paradis. À bientôt, Marion, Emmanuel et toute l''équipe',0,'2025-01-01'),

('google','Zayd Elfallah',5,'Par où commencer… Difficile de rendre justice au Martin en un simple commentaire. Chaque détail est parfait, l''accueil exceptionnel, la décoration magnifique.','en',TRUE,NULL,NULL,'avril 2023',NULL,NULL,NULL,NULL,NULL,0,'2023-05-01'),

('google','Charlie Moore',5,'J''ai passé un séjour extraordinaire au Le Martin Boutique Hotel et je me devais de partager mon expérience ! Du début à la fin, cet endroit a dépassé toutes mes attentes.','en',TRUE,NULL,'solo','juillet 2023',NULL,NULL,NULL,NULL,NULL,0,'2024-01-01'),

('google','Lisa Gaskey',5,'Exceptionnel à tous points de vue ! Nous avons adoré notre séjour au Martin. L''établissement était magnifique, paisible et décoré avec goût.','en',TRUE,NULL,NULL,'novembre 2024',NULL,NULL,NULL,NULL,'Chère Lisa, Merci infiniment pour votre excellent commentaire et vos magnifiques photos ! Nous sommes ravis d''apprendre que vous avez apprécié votre séjour au Martin Boutique Hotel. Bien cordialement, Marion et l''équipe du Martin Boutique Hotel',3,'2025-01-01'),

('google','jaime passee',5,'Ce charmant hôtel-boutique était parfait pour notre séjour à Saint-Martin ! L''intimité des lieux et le service client étaient exceptionnels ! Du début à la fin, notre séjour a été merveilleux ! J''y retournerais sans hésiter.','en',TRUE,'vacances','famille','juillet 2024',NULL,NULL,NULL,NULL,NULL,8,'2025-02-01'),

('google','Jeremy Black',5,'Ma femme et moi avons passé de superbes vacances et un séjour merveilleux à l''hôtel Le Martin Boutique. Je le recommande à tous ceux qui recherchent un hôtel romantique et paisible sur la rive française.','en',TRUE,'vacances','couple','juillet 2024',NULL,NULL,NULL,NULL,NULL,0,'2025-02-01'),

('google','John Cooke',5,'Quel merveilleux séjour ! Je ne taris pas d''éloges sur le service et le personnel… qui sont comme un membre de la famille. L''hôtel est très pittoresque et intime, et le petit-déjeuner est incroyable.','en',TRUE,'vacances','couple','juin 2024',NULL,NULL,NULL,NULL,NULL,0,'2025-02-01'),

('google','Joseph Rosenfeld',5,'C''est notre deuxième visite au Le Martin Boutique Hotel en autant d''années. Situé au sein d''une résidence sécurisée (ouverte en journée), ce joyau immaculé vous accueille. À votre arrivée, tout est mis en œuvre pour que vous vous sentiez chez vous.','en',TRUE,'vacances','couple','février 2024',NULL,NULL,NULL,NULL,'Voici encore un beau cadeau ! Quel plaisir aprés une journée remplie d''émotions. Merci Philip & Joseph ! Merci de construire avec nous cette belle famille qu''est Le Martin ! Marion & Emmanuel et toute l''équipe',6,'2024-03-01'),

('google','Kate Strangway',5,'Notre séjour au Le Martin Boutique Hotel a été tout simplement exceptionnel. L''hôtel est soigneusement conçu, avec un mobilier moderne et sophistiqué. Le personnel se surpasse pour être aimable et attentif à tous les besoins des clients.','en',TRUE,'vacances',NULL,'janvier 2023',NULL,NULL,NULL,NULL,NULL,0,'2023-02-01'),

('google','Robin Bernstein',5,'Nous revenons tout juste d''un séjour d''une semaine exceptionnel dans cet hôtel-boutique exceptionnel et unique. Dès le premier instant, les propriétaires, Marion et Emmanuel, ont tout mis en œuvre pour que notre séjour soit parfait.','en',TRUE,NULL,NULL,'février 2023',NULL,NULL,NULL,NULL,NULL,0,'2023-03-01'),

('google','Ipek Tumay',5,'Si je pouvais donner 100 étoiles, je le ferais ! C''est le meilleur hôtel que j''aie jamais vu ! Les chambres et le personnel sont exceptionnels, nous sommes ravis d''avoir trouvé cet endroit. Je pense que c''est l''endroit le plus unique que j''aie jamais vu.','en',TRUE,'vacances',NULL,'janvier 2023',NULL,NULL,NULL,NULL,NULL,0,'2023-02-01'),

('google','Karim Suwwan',5,'C''est vraiment le meilleur hôtel où j''ai séjourné dans les Caraïbes. Impossible de se tromper. Les propriétaires offrent un service personnalisé imbattable. Ils nous ont réservé les meilleurs restaurants, réservé une excursion en bateau et loué des kayaks.','en',TRUE,NULL,NULL,'janvier 2024',NULL,NULL,NULL,NULL,NULL,0,'2024-02-01'),

('google','bfrazier23',5,'Cet hôtel est idéal pour ceux qui apprécient l''exploration, la détente et les prestations haut de gamme.','en',TRUE,'vacances','couple','décembre 2023',NULL,NULL,NULL,NULL,NULL,9,'2024-01-01'),

('google','E Miller',5,'Quel bel hôtel, mais la qualité du service du personnel a été le point fort de notre séjour. Marion et Idalia étaient extraordinaires, comme si deux membres de votre famille étaient là pour prendre soin de vous.','en',TRUE,'vacances','famille','février 2025',NULL,NULL,NULL,NULL,'Cher/Chère E, Quel plaisir de lire votre commentaire ! Notre objectif est que chaque client se sente comme chez lui, et nous sommes enchantés de savoir qu''Idalia et moi avons rendu votre séjour si spécial. Bien cordialement, L''équipe du Martin Boutique Hotel',2,'2025-04-01'),

('google','Christopher Cozzone',5,'Nous avons séjourné une semaine à l''hôtel Martin début janvier 2023 et avons passé un séjour formidable. Je ne laisse généralement pas d''avis, mais Marion et Emmanuel (les propriétaires) ont été aux petits soins et ont contribué à rendre notre séjour exceptionnel.','en',TRUE,'vacances',NULL,'janvier 2023',NULL,NULL,NULL,NULL,NULL,0,'2023-02-01'),

('google','Melissa Bertrand',5,'Une boutique-hôtel exceptionnelle et pleine de charme, nichée dans une impasse. De l''accueil chaleureux à l''équipe aux petits soins, notre séjour a été tout simplement parfait. Marion nous a accueillis chaleureusement.','en',TRUE,NULL,NULL,'juin 2024',NULL,NULL,NULL,NULL,NULL,0,'2025-02-01'),

('google','Mary Pytko',5,'Le Martin est un charmant petit hôtel chaleureux et accueillant, joliment meublé et décoré. Marion, Emmanuel et leur équipe se mettent en quatre pour que vous vous sentiez comme chez vous.','en',TRUE,'vacances','famille','décembre 2023',NULL,NULL,NULL,NULL,NULL,6,'2024-01-01'),

('google','FranellaMs',5,'L''hôtel est magnifique. Il est magnifiquement conçu, propre et bien organisé. Il est idéalement situé, à proximité de l''Anse Marcel, de l''île Pinéal et de Grand Case. Marrion et Emmanuel font un travail remarquable en accueillant leurs hôtes.','en',TRUE,'vacances',NULL,'janvier 2024',NULL,NULL,NULL,NULL,NULL,0,'2024-02-01'),

('google','Danielle Harper',5,'Un petit bijou incroyable, caché dans une impasse ! Nous aurions aimé rester plus longtemps, mais comme l''hôtel était complet, nous n''avons pu rester que deux nuits. Nous avons réservé via le site web de M. et Mme Smith.','en',TRUE,'vacances','couple',NULL,NULL,NULL,NULL,NULL,NULL,6,'2024-01-01'),

('google','Ayka',5,'Pour ceux qui ne lisent pas beaucoup, ce charmant hôtel-boutique familial est un magnifique joyau caché, conçu avec goût et amour. Réservez-le si vous allez à Saint-Martin, c''est le meilleur choix.','en',TRUE,'vacances',NULL,'janvier 2023',NULL,NULL,NULL,NULL,NULL,0,'2023-02-01'),

('google','Laurent SCHUN',5,'Séjour fantastique. Le Martin est un véritable hôtel-boutique, offrant un service personnalisé de qualité, de belles chambres et de superbes espaces communs décorés avec goût. La piscine est superbe.','en',TRUE,NULL,NULL,'novembre 2024',NULL,NULL,NULL,NULL,'Cher Laurant, Merci beaucoup pour votre superbe retour ! Nous sommes ravis d''apprendre que votre séjour de dernière minute avec vos amis s''est déroulé dans de si bonnes conditions. Avec toute notre gratitude, Marion, Emmanuel, et toute l''équipe du Martin Boutique Hotel',0,'2025-01-01'),

('google','Paul Vershbow',5,'Une fois que vous aurez découvert ce charmant petit hôtel, vous ne voudrez plus le quitter. Comme on peut s''y attendre lors d''un séjour sur « l''Île de la Convivialité », l''hospitalité et la cordialité y sont exemplaires.','en',TRUE,NULL,NULL,'février 2024',NULL,NULL,NULL,NULL,NULL,0,'2024-03-01'),

('google','Ron Clement',5,'Magnifique hôtel-boutique avec une vue imprenable. Personnel et hôte exceptionnels, à l''écoute de tous nos besoins. Cadre intimiste avec de superbes espaces communs et une piscine.','en',TRUE,NULL,'amis','avril 2025',NULL,NULL,NULL,NULL,'Cher Ron, Merci infiniment pour vos gentils mots. Nous sommes ravis que vous ayez apprécié l''intimité de notre maison. Il est vrai que notre petit havre de paix est un peu difficile à trouver… Bien cordialement, Marion et l''équipe du Martin Boutique Hotel',0,'2025-05-01'),

('google','kristie geerts',5,'Expérience incroyable du début à la fin ! Personnel chaleureux et attentionné, aux petits soins pour vous ! Propriété magnifique dans un emplacement idéal ! Je recommande à 100 %.','en',TRUE,'vacances','solo','juillet 2025',NULL,NULL,NULL,NULL,'Chère Kristie, Un grand merci pour votre merveilleux commentaire et pour le partage de ces magnifiques photos. Nous serions ravis de vous accueillir à nouveau pour une expérience tout aussi mémorable. Avec toute notre gratitude, Marion et l''équipe du Martin Boutique Hotel',5,'2025-08-01'),

('google','Joe Sutton',5,'Merveilleux. Service impeccable, petit-déjeuner délicieux, chambres superbes, vue imprenable. Bref, c''était… génial !','en',TRUE,'vacances','solo','janvier 2024',NULL,NULL,NULL,NULL,NULL,0,'2024-02-01'),

('google','Jordan Graeme',5,'Cet hôtel était parfait. Mon seul regret est de n''avoir pas réservé une nuit de plus. Le service était exceptionnel : ils se sont occupés de tout, notamment des taxis et des réservations de restaurant.','en',TRUE,'vacances','couple','mai 2025',NULL,NULL,NULL,NULL,'Cher Jordan, Merci beaucoup pour votre excellent commentaire. Nous sommes ravis d''apprendre que votre séjour au Martin a été parfait. Nous serions ravis de vous accueillir à nouveau très prochainement. Avec nos plus sincères salutations, Marion et toute l''équipe',0,'2025-06-01'),

('google','Alex Wong',5,'Situé du côté français de l''île, au cœur d''une résidence sécurisée entre Orient Beach et Ansel Marcel Beach, se trouve un nouveau joyau : l''hôtel Le Martin. On pourrait le décrire comme votre chez-vous à Hamptons, à Saint-Martin.','en',TRUE,'vacances','couple','mai 2023',NULL,NULL,NULL,NULL,'WAHOOOOO !!!! Quel plaisir, d''arriver très tôt ce matin, de se faufiler tout doucement dans l''hôtel encore tout endormi. Alex vous avez illuminée ma journée ! Marion & Emmanuel Et toute l''équipe du Martin Hôtel',16,'2023-06-01'),

('google','danielle corcoran',5,'C''est un véritable joyau caché. Ici, on se sent vraiment détendu, capable de se déconnecter et de se ressourcer. Nous avons adoré commencer nos journées par le petit-déjeuner artisanal (tout est fait maison).','en',TRUE,'vacances',NULL,'janvier 2023',NULL,NULL,NULL,NULL,NULL,0,'2023-02-01'),

('google','Steven Marinos',5,'C''est l''un des hôtels les plus exceptionnels où j''ai séjourné ! Chaque détail est impeccable, le service est incomparable et l''emplacement est parfait. Si vous envisagez de réserver, n''hésitez pas à ajouter des nuits supplémentaires.','en',TRUE,'vacances','couple','mai 2024',NULL,NULL,NULL,NULL,NULL,2,'2025-02-01'),

('google','Deb D',5,'Nous vous recommandons vivement ce charmant hôtel de charme. Le propriétaire est chaleureux et accueillant, les chambres sont impeccables, bien entretenues et décorées avec goût, les espaces communs sont confortables.','en',TRUE,NULL,NULL,'mai 2023',NULL,NULL,NULL,NULL,NULL,0,'2023-06-01'),

('google','Alina DiRito',5,'Un séjour merveilleux et reposant, avec tout le confort nécessaire ! Nous y retournerions sans hésiter. Les hôtes et le personnel étaient extrêmement accueillants et serviables !','en',TRUE,'vacances','famille','juin 2025',NULL,NULL,NULL,NULL,'Chère Alina, Nous vous remercions chaleureusement pour votre excellent retour. Nous sommes ravis que votre séjour ait été à la fois relaxant et enrichissant. Bien cordialement, Marion et l''équipe de l''Hôtel Boutique Le Martin',3,'2025-09-03'),

('google','shlomi batya',5,'Un endroit incroyable pour des vacances inoubliables. Tant de choses à faire et quel hôtel-boutique ! Un accueil exceptionnel !','en',TRUE,NULL,NULL,'décembre 2022',NULL,NULL,NULL,NULL,NULL,7,'2023-01-01'),

('google','Marie Dahan',5,'C''est le meilleur hôtel-boutique où nous ayons jamais séjourné. Marion, la propriétaire, et toute son équipe sont tout simplement exceptionnelles. Ils sont de très bon conseil et rendent le séjour unique et mémorable.','en',TRUE,'vacances','couple',NULL,NULL,NULL,NULL,NULL,'Marie ! Toute l''équipe du Martin se joint à Emmanuel et moi pour dire un Grand Merci pour ce joli commentaire! Marion & Emmanuel Et toute la team !',3,'2024-01-01'),

('google','Jack Lee',5,'Chambres et personnel exceptionnels. L''espace commun est un immense salon extérieur et nous avions tout l''espace pour nous baigner le soir, car les autres clients semblaient réticents.','en',TRUE,'vacances','couple','avril 2025',NULL,NULL,NULL,NULL,'Cher Jack, merci pour votre gentil commentaire ! Nous sommes ravis que vous ayez apprécié le confort de votre chambre et notre salon extérieur. Nous serions enchantés de vous accueillir à nouveau très prochainement. Marion et l''équipe de l''hôtel Le Martin Boutique',0,'2025-05-01'),

('google','Amy Denny',5,'Nous avons passé quelques jours merveilleux dans ce magnifique hôtel-boutique. Les chambres étaient spacieuses et bien équipées, et le petit-déjeuner était délicieux. Nous reviendrons !','en',TRUE,'vacances','couple','avril 2025',NULL,NULL,NULL,NULL,'Chère Amy, merci beaucoup pour vos aimables paroles ! Nous sommes ravis que vous ayez apprécié la beauté de notre hôtel. Ce fut un réel plaisir de vous accueillir parmi nous. À bientôt, Marion et toute l''équipe du Martin Boutique Hotel',0,'2025-05-01'),

('google','Al Damashek',5,'Hôtel très relaxant, avec une décoration exceptionnelle et un accueil haut de gamme, mais aussi le sentiment d''être seul et d''avoir un espace serein et paisible pour soi. Marion, la propriétaire, vous accueille chaleureusement.','en',TRUE,NULL,NULL,'janvier 2024',NULL,NULL,NULL,NULL,NULL,0,'2024-02-01'),

('google','Jason Grout',5,'Superbe hôtel flambant neuf, juste en face de Pinel. Emplacement idéal pour la partie française, à quelques minutes en voiture de l''Anse Marcel et de la Plage Orientale. Tout est très bien pensé et les chambres et les espaces communs sont magnifiques.','en',TRUE,'vacances','couple','janvier 2023',NULL,NULL,NULL,NULL,'Toute l''équipe du Martin Boutique Hotel vous remercie chaleureusement pour ce magnifique commentaire ! Nous serons ravis de vous accueillir à nouveau ! Marion et Emmanuel',0,'2023-02-01'),

('google','Claudia Sutter',5,'Un hôtel charmant, petit, exquis et très chic, alliant style français et art de vivre caribéen. Nous nous sommes sentis comme chez nous dès notre arrivée et ne pouvons que recommander ce petit coin de paradis.','en',TRUE,'vacances','couple','novembre 2024',NULL,NULL,NULL,NULL,'Chère Claudia, Nous vous remercions chaleureusement pour votre merveilleux commentaire et d''avoir pris le temps de partager votre expérience. Nous sommes ravis d''apprendre que vous vous êtes sentie comme chez vous dès votre arrivée. Avec toute notre gratitude, Marion',1,'2025-01-01'),

('google','Anthony Aiello',5,'Nous sommes allés à Saint-Martin sept fois et cet hôtel est de loin le plus agréable où nous ayons séjourné. Le personnel et l''hôte sont tous excellents et accueillants. Le petit-déjeuner est fabuleux et les chambres sont superbes.','en',TRUE,'vacances',NULL,'décembre 2022',NULL,NULL,NULL,NULL,'Un grand merci à Anthony pour cette découverte et cette expérience inoubliables à Saint-Martin ! Toute l''équipe du Martin Hôtel se joint à nous pour vous remercier. Marion et Emmanuel',0,'2023-01-01'),

('google','Gwendolyn Tan',5,'Notre séjour a été très agréable ! Quel charmant hôtel boutique, si bien conçu ! Idéalement situé, il offre une vue imprenable sur l''île Pinel. Nous recommandons vivement ce nouvel hôtel boutique confidentiel, tenu par un couple de propriétaires charmants.','en',TRUE,'vacances',NULL,'janvier 2023',NULL,NULL,NULL,NULL,NULL,6,'2023-02-01'),

('google','Paloma Aelyon',5,'De l''attention portée aux détails de décoration aux délicieux petits-déjeuners, en passant par un emplacement magnifique et un personnel qui vous fait vraiment sentir comme chez vous, Le Martin a été un moment inoubliable.','en',TRUE,NULL,NULL,'mars 2023',NULL,NULL,NULL,NULL,NULL,0,'2023-04-01'),

('google','Lou Manzo',5,'L''un des meilleurs hôtels où j''aie séjourné. Le petit-déjeuner et la vue sont exceptionnels. Marion, Emmanuel et toute l''équipe sont d''une gentillesse incroyable et on s''y sent comme à la maison.','en',TRUE,NULL,NULL,'novembre 2022',NULL,NULL,NULL,NULL,'Merci Lou ! Nous avons hâte de vous revoir ! L''équipe Marion, Emmanuel et Le Martin',0,'2022-12-01'),

('google','Danny Goldstein',5,'Des hôtes charmants, un espace magnifiquement conçu, des petits-déjeuners savoureux et une vue magnifique sur la baie. Une expérience merveilleuse. J''y retournerais volontiers.','en',TRUE,'vacances','couple','mars 2025',NULL,NULL,NULL,NULL,'Cher Danny, merci beaucoup pour vos gentils mots ! Nous sommes ravis que vous ayez apprécié votre séjour. Ce fut un plaisir de vous accueillir. Marion',0,'2025-04-01'),

('google','Michelle',5,'Ivanna, Idaylia et Marion, ainsi que toute l''équipe du Martin, vous accueillent chaleureusement et vous font sentir comme chez vous. L''hôtel est magnifique et ils vous donneront de précieux conseils sur les endroits à visiter.','en',TRUE,'vacances','solo','avril 2024',NULL,NULL,NULL,NULL,NULL,0,'2025-02-01'),

('google','Terry Yano',5,'Un hôtel-boutique des plus confortables. Nous avons adoré son ambiance intimiste et son design fabuleux : élégant sans être prétentieux. La cuisine était excellente. Nous reviendrons sans hésiter.','en',TRUE,'vacances','famille','décembre 2023',NULL,NULL,NULL,NULL,NULL,0,'2024-01-01'),

('google','Bernardo Menendez',5,'Superbe expérience ! Tout était parfait : l''endroit, les gens, la nourriture, les chambres et l''ambiance !','en',TRUE,'vacances','couple','juin 2024',NULL,NULL,NULL,NULL,NULL,0,'2025-02-01'),

('google','Donna Ravenhill',5,'Quelques nuits fantastiques, Emanuel est très hospitalier, très sympathique et compétent - nous reviendrions certainement ici, l''hôtel est de bon goût, la décoration est exceptionnelle et le petit-déjeuner est également délicieux.','en',TRUE,'vacances','couple','mars 2024',NULL,NULL,NULL,NULL,NULL,0,'2025-02-01'),

('google','Donovan Fuhs',5,'Quel séjour incroyable ! La vue était magnifique et la piscine ainsi que les espaces communs étaient fantastiques.','en',TRUE,'vacances','famille','août 2025',NULL,NULL,NULL,NULL,'Cher Donovan, nous sommes ravis que vous ayez apprécié Le Martin, un lieu conçu pour vous permettre de vous détendre et de vous sentir comme chez vous. Ce fut un plaisir de vous accueillir. Bien cordialement, Marion et l''équipe du Martin',0,'2025-09-03'),

('google','Frank v.d. Nieuwenhuijzen',5,'Hôtel-boutique bien entretenu et bien organisé. Belles chambres. Personnel sympathique et compétent. Nous y retournerons sans hésiter lors de notre prochain séjour à Sint Maarten.','en',TRUE,'vacances','couple','janvier 2025',NULL,NULL,NULL,NULL,'Cher Frank, Merci beaucoup pour vos aimables paroles ! Nous sommes ravis que vous ayez apprécié notre hôtel-boutique, nos magnifiques chambres et notre équipe dévouée. Cordialement. Marion',0,'2025-02-01'),

('google','Steve Redburn',5,'Un endroit fantastique pour se détendre et profiter d''un point de départ pour explorer la mer et ses excellents restaurants. Un peu à l''écart, c''est l''une des meilleures raisons de s''y rendre.','en',TRUE,'vacances','couple','février 2025',NULL,NULL,NULL,NULL,'Cher Steve, Merci pour vos aimables paroles ! Nous sommes ravis que vous ayez trouvé Le Martin l''endroit idéal pour vous détendre et découvrir les incroyables restaurants de l''île. Cordialement, Marion et l''équipe du Martin Boutique Hotel',0,'2025-04-01'),

('google','Roeland Van der Maas',5,'L''un des meilleurs que nous ayons eu. Logement neuf, propre et paisible. Propriétaires charmants. Nous reviendrons sans hésiter lors de notre prochain séjour à SXM.','en',TRUE,'vacances','couple','juillet 2023',NULL,NULL,NULL,NULL,'Roeland, Emmanuel, toute l''équipe et moi-même tenons à vous remercier chaleureusement pour votre très gentil commentaire ! Mille mercis pour votre gentillesse et votre bienveillance ! À très bientôt ! Marion et Emmanuel Et toute l''équipe !',3,'2023-08-01'),

('google','Christian Powers',5,'Ma femme et moi avons séjourné 4 nuits et avons hâte de revenir l''année prochaine. Tout ce dont vous aviez besoin était simplement une visite à la réception et pris en charge. L''attention personnelle était exemplaire.','en',TRUE,'vacances','couple','mai 2024',NULL,NULL,NULL,NULL,NULL,3,'2025-02-01'),

('google','Stacy Meyer',5,'Quel bel hôtel avec un excellent service et un petit-déjeuner au bord de la piscine ! La vue est spectaculaire et les propriétaires sont très sympathiques ! Nous y retournerons avec plaisir !','en',TRUE,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,'2024-01-01'),

('google','Marianne Gambelli',4,'Une expérience boutique avec un service exceptionnel.','en',TRUE,'vacances','famille','janvier 2026',NULL,NULL,NULL,NULL,NULL,0,'2026-02-03'),

('google','Bjørn Simonsen',5,'Nous n''y avons passé qu''une nuit, mais nous avons adoré. Nous reviendrons.','en',TRUE,NULL,NULL,'février 2025',NULL,NULL,NULL,NULL,'Cher Bjor, Merci beaucoup pour vos gentils mots concernant votre séjour chez nous ! Nous sommes ravis d''apprendre que vous l''avez apprécié, même s''il fut court. Ce serait un honneur de vous accueillir à nouveau pour un séjour plus long prochainement. Bien cordialement, Marion',0,'2025-03-01'),

('google','Elena Oprea',5,'Chambres charmantes, personnel charmant, ambiance agréable. Un endroit idéal pour se détendre.','en',TRUE,NULL,NULL,'décembre 2022',NULL,NULL,NULL,NULL,'Elena, Merci de revenir chaque fois faire un petit stop chez nous entre deux voyages en mer ! A trés vite. Marion & Emmanuel Et la team Martin Hôtel',0,'2023-01-01'),

('google','Karen Jacob',5,'Nous avons adoré notre séjour à l''Hôtel Boutique Le Martin.','en',TRUE,'vacances','couple','février 2024',NULL,NULL,NULL,NULL,NULL,0,'2024-03-01'),

('google','Emily Ellis',5,'Nous avons adoré notre séjour au Martin ! We loved our time Le Martin!','en',FALSE,'vacances','amis','mars 2025',5.0,5.0,5.0,ARRAY['Luxueux','Beau panorama'],'Chère Emily, Merci beaucoup pour vos gentils mots ! Nous sommes ravis d''apprendre que vous et vos amis avez passé un excellent séjour au Martin Boutique Hotel. Nous espérons vous accueillir à nouveau pour un séjour inoubliable à Saint-Martin. Cordialement, Marion et l''équipe du Martin Boutique Hotel',0,'2025-04-01'),

('google','Deborah Lee',5,'Personnel formidable ! Endroit parfait, je recommande vivement !','en',TRUE,'vacances','couple','novembre 2024',NULL,NULL,NULL,NULL,'Chère Deborah, Quel plaisir de lire votre message ! Je suis ravie que vous ayez passé un si agréable séjour parmi nous. Savoir que la chambre Marcelle a rendu votre séjour inoubliable me touche profondément. Bien à vous, Marion',0,'2025-01-01'),

('google','Allard',5,'Séjour en couple, hôtel magnifique avec vue imprenable. Luxueux, beau panorama, romantique, calme.','fr',FALSE,'vacances','couple','janvier 2026',5.0,5.0,4.0,ARRAY['Luxueux','Beau panorama','Romantique','Calme'],NULL,1,'2026-02-03'),

('google','HK',5,'Design et hospitalité exquis.','en',FALSE,NULL,NULL,'février 2023',NULL,NULL,NULL,NULL,NULL,0,'2023-03-01'),

('google','roberto spreafico',4,'Séjour famille. Belle vue panoramique, calme, high-tech. La colazione può essere migliorata.','it',FALSE,'vacances','famille','avril 2025',4.0,4.0,3.0,ARRAY['Beau panorama','Calme','High-tech'],'Cher Roberto, Merci beaucoup pour votre évaluation et d''avoir choisi Le Martin pour votre séjour. Nous sommes ravis que vous ayez passé un agréable séjour parmi nous. Si vous souhaitez partager ce qui aurait pu rendre votre séjour encore plus agréable, n''hésitez pas. Cordialement, Marion et toute l''équipe',0,'2025-05-01'),

('google','Anna Bramnik',5,'Séjour parfait. 5 étoiles.','fr',FALSE,NULL,NULL,'avril 2025',5.0,5.0,5.0,NULL,'Chère Anna, merci beaucoup pour votre note 5 étoiles ; votre confiance et votre soutien nous sont précieux. Nous serions ravis de vous accueillir à nouveau prochainement à Saint-Martin. Cordialement, Marion et l''équipe du Martin Boutique Hotel',0,'2025-05-01'),

('google','Steven Sulpizio',5,'Séjour couple, hôtel magnifique avec beau panorama, romantique et calme.','fr',FALSE,'vacances','couple','janvier 2025',5.0,5.0,5.0,ARRAY['Beau panorama','Romantique','Calme','Bon rapport qualité-prix'],'Merci infiniment pour votre avis 5 étoiles et pour le partage de vos magnifiques photos ! Marion',0,'2025-02-01'),

('google','Gigi Chehabeddine',5,'Séjour famille avec enfants, hôtel magnifique, luxueux, romantique et calme.','fr',FALSE,'vacances','famille','décembre 2024',5.0,5.0,5.0,ARRAY['Luxueux','Beau panorama','Romantique','Calme'],'Chère Gigi, Votre chaleureux message à votre retour nous a profondément touchés. Ce fut une joie immense d''accueillir votre adorable famille et de partager ces moments précieux avec vous. Avec toute notre amitié, Marion et Emmanuel L''équipe du Martin Boutique Hôtel',0,'2025-01-01'),

('google','Jose Bonaria - Paseando por el Mundo',5,'Séjour couple, hôtel magnifique avec beau panorama, romantique, calme, bon rapport qualité-prix et high-tech.','fr',FALSE,'vacances','couple','décembre 2024',5.0,5.0,5.0,ARRAY['Beau panorama','Romantique','Calme','Bon rapport qualité-prix','High-tech'],NULL,0,'2025-01-01'),

('google','Ana Isabel Vieira Branco',5,'Séjour famille avec enfant, hôtel magnifique.','pt',FALSE,NULL,NULL,'novembre 2024',5.0,5.0,5.0,NULL,'Chère Ana, Merci infiniment pour votre gentil commentaire et d''avoir partagé votre expérience au Le Martin Boutique Hôtel. Ce fut un réel plaisir de vous accueillir, vous et votre famille, lors de votre long séjour dans la chambre de Marius. Marion',0,'2025-01-01'),

('google','Beuk Hooft Graafland',5,'Séjour famille, hôtel luxueux et calme.','fr',FALSE,'vacances','famille','mai 2024',5.0,5.0,4.0,ARRAY['Luxueux','Calme'],NULL,0,'2025-02-01'),

('google','Madelon Peck',5,'Dès notre arrivée au Martin, nous avons su que nous avions trouvé un lieu vraiment exceptionnel. Cet hôtel-boutique cinq étoiles transcende l''expérience de luxe classique, offrant un havre de paix intime et personnalisé qui dépasse toutes les attentes.','en',TRUE,'vacances','famille','mars 2025',NULL,NULL,NULL,NULL,'Chère Madelon, Waouh ! Vos mots nous ont vraiment touchés ! Merci d''avoir pris le temps de partager ce magnifique commentaire sur votre expérience au Martin Boutique Hotel. Sincères salutations, Marion, Idalia et l''équipe du Martin Boutique Hotel',0,'2025-04-01'),

-- ══════════════════════════════════════════════════════
-- TRIPADVISOR REVIEWS
-- ══════════════════════════════════════════════════════

('tripadvisor','cwerning',5,'J''ai hésité avant de réserver au Martin – six chambres, pas de restaurant ni de bar, cela me paraissait presque trop petit – mais cela s''est révélé être l''un des meilleurs choix de mon voyage. Hôtel remarquable, équipe exceptionnelle.','fr',FALSE,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,'2024-12-03'),

('tripadvisor','T9256TQ',5,'Expérience exceptionnelle au Martin hôtel. Superbe décoration, de la chambre à la piscine. Le petit déjeuner était délicieux. Mais c''est surtout la gentillesse et la bienveillance de Marion, Emmanuelle et toute leur équipe qui a rendu notre séjour inoubliable. Un grand merci !','fr',FALSE,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,'2024-01-01'),

('tripadvisor','SimonJames1978',5,'Nous venons de quitter l''hôtel et, franchement, nous n''avions pas envie de partir. Cet endroit est magnifique – nous le recommandons vivement.','en',TRUE,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,'2025-01-03'),

('tripadvisor','alissaturpin',5,'Je suis tellement contente que nous ayons trouvé cet hôtel, il était vraiment merveilleux ! On sent que les propriétaires y ont mis tout leur coeur et le résultat est magnifique.','en',TRUE,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,'2025-01-03'),

('tripadvisor','katherinej721',5,'Marion était formidable. Je l''ai contactée par e-mail avant notre voyage et elle nous a suggéré plusieurs clubs de plage et restaurants. Elle a réservé notre séjour, ce qui était vraiment très pratique.','en',TRUE,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,'2025-05-01'),

('tripadvisor','Mariebur',5,'Elles savent ce qu''est un excellent service. Ivana et Idalia offrent un service irréprochable pour que vous vous sentiez comme chez vous ! Piscine et espace détente agréables.','en',TRUE,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,'2025-05-01'),

('tripadvisor','henricb2023',5,'Hôtel fantastique à deux pas de Pinel Island et à 10 minutes de Grand Case. La propriétaire, Marion, est une femme absolument formidable et passionnée par le service.','en',TRUE,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,'2025-03-01'),

('tripadvisor','johncP791EU',5,'Je n''écris généralement pas d''avis sur les hôtels, mais Le Martin est exceptionnel. Service irréprochable, cadre magnifique, petit-déjeuner délicieux.','en',TRUE,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,'2025-03-01'),

('tripadvisor','juliehS4188RA',5,'Cet hôtel est absolument parfait. Son design est magnifique et l''atmosphère créée par Marion et son équipe est vraiment unique.','en',TRUE,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,'2024-01-01'),

('tripadvisor','CHRIANDR',5,'Nous avons passé trois nuits à l''hôtel Le Martin et c''était fantastique. La chambre était charmante et le salon, le bar et la piscine étaient très agréables.','en',TRUE,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,'2025-02-01'),

('tripadvisor','salnafisi',5,'Dès l''instant où l''on pénètre dans le cadre paisible du Martin, on est immédiatement transporté dans un paradis tropical au design savoyard. Service irréprochable et petit-déjeuner délicieux.','en',TRUE,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,'2024-01-01'),

('tripadvisor','FreeportLisa_g',5,'Ce fut une pause bien méritée après la folie pré-électorale aux États-Unis. Hôtel magnifique, équipe attentionnée, endroit parfait pour se ressourcer.','en',TRUE,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,'2025-02-01'),

('tripadvisor','JONN391',5,'Nouvel hôtel de charme de petite taille. Niché comme une oasis de verdure au cœur de Cul de Sac, il dispose d''une magnifique terrasse avec petite piscine et espaces détente.','en',TRUE,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,'2025-02-01'),

('tripadvisor','NW8London',5,'Nous avons adoré notre séjour. Marion, la propriétaire, était adorable et très accueillante. C''était un vrai plaisir de discuter avec elle. L''hôtel est magnifiquement décoré et conçu avec beaucoup de goût.','en',TRUE,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,'2025-03-01');
