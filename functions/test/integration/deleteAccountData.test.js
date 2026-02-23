const assert = require("node:assert/strict");
const {before, beforeEach, test} = require("node:test");

const admin = require("firebase-admin");
const {deleteAccountData} = require("../../index");

const OWNER_UID = "owner-test-uid";
const FOLLOWER_UID = "follower-test-uid";
const OTHER_UID = "other-test-uid";

function ensureEmulatorEnvironment() {
  if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
    throw new Error(
        "This integration test must run with Firestore/Auth emulators via firebase emulators:exec.",
    );
  }
}

async function clearFirestore() {
  const db = admin.firestore();
  const collections = await db.listCollections();
  for (const collection of collections) {
    const documents = await collection.listDocuments();
    for (const docRef of documents) {
      await db.recursiveDelete(docRef);
    }
  }
}

async function clearAuthUsers() {
  const auth = admin.auth();
  let nextPageToken = undefined;

  do {
    const result = await auth.listUsers(1000, nextPageToken);
    await Promise.all(result.users.map((user) => auth.deleteUser(user.uid)));
    nextPageToken = result.pageToken;
  } while (nextPageToken);
}

async function expectUserDeleted(uid) {
  await assert.rejects(
      admin.auth().getUser(uid),
      (error) => error?.code === "auth/user-not-found",
  );
}

before(() => {
  ensureEmulatorEnvironment();
});

beforeEach(async () => {
  await clearFirestore();
  await clearAuthUsers();
});

test("throws unauthenticated when auth context is missing", async () => {
  await assert.rejects(
      deleteAccountData.run({}),
      (error) => error?.code === "unauthenticated",
  );
});

test("deletes owned data, follow bindings, profile subtree, and auth user", async () => {
  const db = admin.firestore();

  await admin.auth().createUser({uid: OWNER_UID});
  await admin.auth().createUser({uid: FOLLOWER_UID});
  await admin.auth().createUser({uid: OTHER_UID});

  await db.collection("rule_sets").doc("owner-rs-1").set({ownerUid: OWNER_UID});
  await db.collection("rule_sets").doc("owner-rs-2").set({ownerUid: OWNER_UID});
  await db.collection("rule_sets").doc("other-rs-1").set({ownerUid: OTHER_UID});

  await db.collection("users").doc(OWNER_UID).set({ownerName: "Owner"});
  await db
      .collection("users")
      .doc(OWNER_UID)
      .collection("follows")
      .doc("owner-follow-self")
      .set({ruleSetOwnerUid: OWNER_UID});

  await db.collection("users").doc(FOLLOWER_UID).set({ownerName: "Follower"});
  await db
      .collection("users")
      .doc(FOLLOWER_UID)
      .collection("follows")
      .doc("owner-rs-1")
      .set({ruleSetOwnerUid: OWNER_UID});
  await db
      .collection("users")
      .doc(FOLLOWER_UID)
      .collection("follows")
      .doc("owner-rs-2")
      .set({ruleSetOwnerUid: OWNER_UID});
  await db
      .collection("users")
      .doc(FOLLOWER_UID)
      .collection("follows")
      .doc("other-rs-1")
      .set({ruleSetOwnerUid: OTHER_UID});

  const result = await deleteAccountData.run({
    auth: {uid: OWNER_UID},
  });

  assert.equal(result.success, true);
  assert.equal(result.deletedRuleSetCount, 2);
  assert.equal(result.deletedFollowBindingCount, 3);

  const ownedRuleSets = await db
      .collection("rule_sets")
      .where("ownerUid", "==", OWNER_UID)
      .get();
  assert.equal(ownedRuleSets.size, 0);

  const otherRuleSet = await db.collection("rule_sets").doc("other-rs-1").get();
  assert.equal(otherRuleSet.exists, true);

  const ownerFollows = await db
      .collectionGroup("follows")
      .where("ruleSetOwnerUid", "==", OWNER_UID)
      .get();
  assert.equal(ownerFollows.size, 0);

  const ownerUserDoc = await db.collection("users").doc(OWNER_UID).get();
  assert.equal(ownerUserDoc.exists, false);

  const followerOtherFollow = await db
      .collection("users")
      .doc(FOLLOWER_UID)
      .collection("follows")
      .doc("other-rs-1")
      .get();
  assert.equal(followerOtherFollow.exists, true);

  await expectUserDeleted(OWNER_UID);
});
