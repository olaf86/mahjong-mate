const admin = require('firebase-admin');

const projectId = process.env.GCLOUD_PROJECT || 'mahjong-mate-app';
process.env.FIREBASE_AUTH_EMULATOR_HOST =
  process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9099';
process.env.FIRESTORE_EMULATOR_HOST =
  process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';

admin.initializeApp({ projectId });

const db = admin.firestore();
const auth = admin.auth();

const screenshotUser = {
  uid: 'screenshot-owner-001',
  email: 'screenshot@example.com',
  password: 'Passw0rd!',
  displayName: '雀メイト運営',
};

const rulesTemplate = {
  players: 'four',
  matchType: 'tonnan',
  startingPoints: 25000,
  boxTenThreshold: 'zero',
  boxTenBehavior: 'end',
  kuitan: 'on',
  sakizuke: 'ato',
  headBump: 'atama',
  renchan: 'oyaTenpai',
  oorasuStop: 'on',
  goRenchanTwoHan: 'off',
  nagashiMangan: 'on',
  chiitoitsuFourTiles: 'off',
  shaNyu: 'on',
  shaNyuOption: 'suddenDeath',
  kandora: 'on',
  uradora: 'on',
  redDora: { enabled: true, count: 3 },
  specialDora: [],
  score: {
    oka: 0,
    returnPoints: 30000,
    uma: '20-10',
    riichiStick: 'topTake',
  },
  yakuman: { allowMultiple: true, allowDouble: true },
  freeText: '',
};

const ruleSets = [
  {
    id: 'rs_weekend_friends',
    name: '友だちと週末麻雀',
    description: '赤あり・喰いタンあり。気軽に遊べる定番ルール。',
    shareCode: 'MJM-WKND',
    visibility: 'public',
    rules: {
      ...rulesTemplate,
      freeText: 'トビ終了あり。',
    },
  },
  {
    id: 'rs_club_standard',
    name: 'サークル標準ルール',
    description: 'サークルで共有している標準設定。',
    shareCode: 'MJM-CLUB',
    visibility: 'public',
    rules: {
      ...rulesTemplate,
      shaNyuOption: 'untilWestRoundEnd',
      freeText: '同点は上家取り。',
    },
  },
  {
    id: 'rs_tournament',
    name: '大会向け競技ルール',
    description: '赤なし・一発/裏ドラあり。競技寄りの設定。',
    shareCode: 'MJM-TOUR',
    visibility: 'public',
    rules: {
      ...rulesTemplate,
      redDora: { enabled: false, count: 0 },
      freeText: '開始10分前集合。',
    },
  },
  {
    id: 'rs_local_house',
    name: 'ローカルハウスルール',
    description: '普段のメンバー向けローカルルール。',
    shareCode: null,
    visibility: 'private',
    rules: {
      ...rulesTemplate,
      chiitoitsuFourTiles: 'on',
      freeText: '北抜きなし、オカなし。',
    },
  },
];

async function ensureUser() {
  try {
    const existing = await auth.getUser(screenshotUser.uid);
    await auth.updateUser(existing.uid, {
      email: screenshotUser.email,
      password: screenshotUser.password,
      displayName: screenshotUser.displayName,
      emailVerified: true,
    });
  } catch (error) {
    if (error.code !== 'auth/user-not-found') {
      throw error;
    }
    await auth.createUser({
      uid: screenshotUser.uid,
      email: screenshotUser.email,
      password: screenshotUser.password,
      displayName: screenshotUser.displayName,
      emailVerified: true,
    });
  }
}

async function deleteCollectionDocs(collectionRef) {
  const snapshot = await collectionRef.get();
  const batch = db.batch();
  snapshot.docs.forEach((doc) => batch.delete(doc.ref));
  if (!snapshot.empty) {
    await batch.commit();
  }
}

async function resetOwnerData() {
  const ownRules = await db
    .collection('rule_sets')
    .where('ownerUid', '==', screenshotUser.uid)
    .get();
  if (!ownRules.empty) {
    const batch = db.batch();
    ownRules.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
  }

  await deleteCollectionDocs(
    db.collection('users').doc(screenshotUser.uid).collection('follows'),
  );
}

function now() {
  return admin.firestore.FieldValue.serverTimestamp();
}

function buildItems(name) {
  return [
    {
      id: `${name}-basic`,
      category: 'basic',
      title: '基本設定',
      description: '4人打ち / 東南戦',
      priority: 0,
    },
    {
      id: `${name}-dora`,
      category: 'dora',
      title: 'ドラ設定',
      description: '赤ドラ・裏ドラ',
      priority: 1,
    },
    {
      id: `${name}-score`,
      category: 'score',
      title: '点数設定',
      description: '返し30000 / ウマ20-10',
      priority: 2,
    },
  ];
}

async function seedRuleSets() {
  for (const [index, ruleSet] of ruleSets.entries()) {
    await db.collection('rule_sets').doc(ruleSet.id).set({
      name: ruleSet.name,
      description: ruleSet.description,
      ownerName: screenshotUser.displayName,
      ownerUid: screenshotUser.uid,
      shareCode: ruleSet.shareCode,
      visibility: ruleSet.visibility,
      updatedAt: now(),
      items: buildItems(ruleSet.id),
      rules: ruleSet.rules,
    });

    await db
      .collection('users')
      .doc(screenshotUser.uid)
      .collection('follows')
      .doc(ruleSet.id)
      .set({
        order: index,
        ruleSetId: ruleSet.id,
        ruleSetOwnerUid: screenshotUser.uid,
        followedAt: now(),
      });
  }
}

async function main() {
  await ensureUser();
  await resetOwnerData();
  await seedRuleSets();

  console.log('Seed completed for screenshot mode.');
  console.log(`projectId: ${projectId}`);
  console.log(`uid: ${screenshotUser.uid}`);
  console.log(`email: ${screenshotUser.email}`);
  console.log('rule_sets:', ruleSets.map((item) => item.id).join(', '));
}

main()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await admin.app().delete();
  });
