const admin = require("firebase-admin");
const {onCall, HttpsError} = require("firebase-functions/v2/https");

admin.initializeApp();

const BATCH_LIMIT = 500;
const IN_QUERY_LIMIT = 10;

async function deleteRefsInBatches(db, refs) {
  let batch = db.batch();
  let count = 0;

  for (const ref of refs) {
    batch.delete(ref);
    count++;
    if (count >= BATCH_LIMIT) {
      await batch.commit();
      batch = db.batch();
      count = 0;
    }
  }

  if (count > 0) {
    await batch.commit();
  }
}

function chunk(array, size) {
  const chunks = [];
  for (let i = 0; i < array.length; i += size) {
    chunks.push(array.slice(i, i + size));
  }
  return chunks;
}

exports.deleteAccountData = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }

  const uid = request.auth.uid;
  const db = admin.firestore();

  try {
    const ownedSnapshot = await db
        .collection("rule_sets")
        .where("ownerUid", "==", uid)
        .get();
    const ownedRuleSetIds = ownedSnapshot.docs.map((doc) => doc.id);

    if (ownedSnapshot.docs.length > 0) {
      const ownedRefs = ownedSnapshot.docs.map((doc) => doc.ref);
      await deleteRefsInBatches(db, ownedRefs);
    }

    // Remove follow bindings in other users that point to deleted rule sets.
    for (const ids of chunk(ownedRuleSetIds, IN_QUERY_LIMIT)) {
      const followsSnapshot = await db
          .collectionGroup("follows")
          .where(admin.firestore.FieldPath.documentId(), "in", ids)
          .get();
      if (followsSnapshot.docs.length === 0) continue;
      const followRefs = followsSnapshot.docs.map((doc) => doc.ref);
      await deleteRefsInBatches(db, followRefs);
    }

    // Delete user profile and all subcollections (including own follows).
    const userDocRef = db.collection("users").doc(uid);
    await db.recursiveDelete(userDocRef);

    // Finally delete Firebase Auth account.
    await admin.auth().deleteUser(uid);

    return {
      success: true,
      deletedRuleSetCount: ownedRuleSetIds.length,
    };
  } catch (error) {
    throw new HttpsError("internal", `Failed to delete account data: ${error}`);
  }
});
